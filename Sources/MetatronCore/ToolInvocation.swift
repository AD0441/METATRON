import Foundation
import Darwin

/// Owns one process group. All mutable state, pipe reads and completion run on
/// `queue`; cancellation can arrive before launch, during execution or at exit.
/// A process group also stops encoder/office helper children on cancellation.
final class ToolInvocation: @unchecked Sendable {
    private enum StopReason { case cancelled, timedOut }
    private let queue = DispatchQueue(label: "metatron.tool", qos: .utility)
    private let tool: URL
    private let arguments: [String]
    private let directory: URL?
    private let timeout: TimeInterval
    private let environment: [String: String]
    private var continuation: CheckedContinuation<String, Error>?
    private var pid: pid_t = 0
    private var stopReason: StopReason?
    private var finished = false
    private var exitStatus: Int32?
    private var output = Data(), errors = Data()
    private var outputSource: DispatchSourceRead?, errorSource: DispatchSourceRead?
    private var exitSource: DispatchSourceProcess?
    private var timeoutWork: DispatchWorkItem?, killWork: DispatchWorkItem?
    private let diagnosticLimit = 1_048_576

    init(tool: URL, arguments: [String], directory: URL?, timeout: TimeInterval, environment: [String: String]) {
        self.tool = tool; self.arguments = arguments; self.directory = directory
        self.timeout = timeout; self.environment = environment
    }

    func start(_ continuation: CheckedContinuation<String, Error>) {
        queue.async {
            self.continuation = continuation
            if self.stopReason != nil { self.finish(.failure(CancellationError())); return }
            guard self.timeout.isFinite, self.timeout > 0 else {
                self.finish(.failure(MetatronError.badData("El tiempo límite debe ser mayor que cero."))); return
            }
            do { try self.launch() } catch { self.finish(.failure(error)) }
        }
    }

    func cancel() { queue.async { self.stop(.cancelled) } }

    private func launch() throws {
        var stdoutFD = [Int32](repeating: -1, count: 2)
        var stderrFD = [Int32](repeating: -1, count: 2)
        guard pipe(&stdoutFD) == 0 else { throw posixError(errno) }
        guard pipe(&stderrFD) == 0 else {
            stdoutFD.forEach { Darwin.close($0) }; throw posixError(errno)
        }
        // Only the read ends are non-blocking. The child must never lose output
        // because a pipe writer encountered EAGAIN.
        for fd in stdoutFD + stderrFD { _ = fcntl(fd, F_SETFD, FD_CLOEXEC) }
        for fd in [stdoutFD[0], stderrFD[0]] { _ = fcntl(fd, F_SETFL, O_NONBLOCK) }
        var actions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        posix_spawn_file_actions_init(&actions)
        posix_spawnattr_init(&attributes)
        defer {
            posix_spawn_file_actions_destroy(&actions)
            posix_spawnattr_destroy(&attributes)
            Darwin.close(stdoutFD[1]); Darwin.close(stderrFD[1])
        }
        func check(_ code: Int32) throws { if code != 0 { throw posixError(code) } }
        do {
            try check(posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0))
            try check(posix_spawn_file_actions_adddup2(&actions, stdoutFD[1], STDOUT_FILENO))
            try check(posix_spawn_file_actions_adddup2(&actions, stderrFD[1], STDERR_FILENO))
            if let directory { try check(posix_spawn_file_actions_addchdir_np(&actions, directory.path)) }
            try check(posix_spawnattr_setpgroup(&attributes, 0))
            var signals = sigset_t()
            sigemptyset(&signals)
            try check(posix_spawnattr_setsigmask(&attributes, &signals))
            sigemptyset(&signals); sigaddset(&signals, SIGTERM); sigaddset(&signals, SIGINT); sigaddset(&signals, SIGPIPE)
            try check(posix_spawnattr_setsigdefault(&attributes, &signals))
            try check(posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF)))
            let argv = ([tool.path] + arguments).map { strdup($0) } + [nil]
            let env = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
                .map { strdup("\($0.key)=\($0.value)") } + [nil]
            defer { argv.forEach { free($0) }; env.forEach { free($0) } }
            try argv.withUnsafeBufferPointer { args in
                try env.withUnsafeBufferPointer { vars in
                    try check(posix_spawn(&pid, tool.path, &actions, &attributes,
                                          UnsafeMutablePointer(mutating: args.baseAddress!),
                                          UnsafeMutablePointer(mutating: vars.baseAddress!)))
                }
            }
        } catch {
            Darwin.close(stdoutFD[0]); Darwin.close(stderrFD[0]); throw error
        }
        outputSource = reader(stdoutFD[0], isError: false)
        errorSource = reader(stderrFD[0], isError: true)
        let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: queue)
        source.setEventHandler {
            var status: Int32 = 0
            var result: pid_t
            repeat { result = waitpid(self.pid, &status, 0) } while result < 0 && errno == EINTR
            self.exitStatus = result == self.pid ? status : -1
            self.exitSource?.cancel(); self.exitSource = nil
            // A parent may exit on TERM while a helper ignores it. Do not leave
            // that helper alive holding the pipes or temporary files open.
            if self.stopReason != nil { self.killGroup() }
            self.finishIfReady()
        }
        exitSource = source; source.resume()
        let deadline = DispatchWorkItem { [weak self] in self?.stop(.timedOut) }
        timeoutWork = deadline
        queue.asyncAfter(deadline: .now() + timeout, execute: deadline)
    }

    private func reader(_ fd: Int32, isError: Bool) -> DispatchSourceRead {
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setCancelHandler { Darwin.close(fd) }
        source.setEventHandler {
            var buffer = [UInt8](repeating: 0, count: 32_768)
            // Bound each turn so continuous output cannot starve cancellation.
            for _ in 0..<16 {
                let count = Darwin.read(fd, &buffer, buffer.count)
                if count > 0 {
                    if isError { self.append(Data(buffer.prefix(count)), to: &self.errors) }
                    else { self.append(Data(buffer.prefix(count)), to: &self.output) }
                } else if count == 0 || (errno != EAGAIN && errno != EINTR) {
                    if isError { self.errorSource?.cancel(); self.errorSource = nil }
                    else { self.outputSource?.cancel(); self.outputSource = nil }
                    self.finishIfReady(); return
                } else if errno == EAGAIN { return }
            }
        }
        source.resume()
        return source
    }

    private func append(_ bytes: Data, to data: inout Data) {
        data.append(bytes)
        if data.count > diagnosticLimit { data.removeFirst(data.count - diagnosticLimit) }
    }

    private func stop(_ reason: StopReason) {
        guard !finished, stopReason == nil else { return }
        stopReason = reason
        guard pid > 0 else { return }
        Darwin.kill(-pid, SIGTERM)
        let force = DispatchWorkItem { [weak self] in self?.killGroup() }
        killWork = force
        queue.asyncAfter(deadline: .now() + 0.5, execute: force)
    }

    private func killGroup() {
        guard !finished, pid > 0 else { return }
        Darwin.kill(-pid, SIGKILL)
        // A broken helper that detached from the group must not keep our reads
        // open indefinitely. The owned child is still reaped before completion.
        outputSource?.cancel(); outputSource = nil
        errorSource?.cancel(); errorSource = nil
        finishIfReady()
    }

    private func finishIfReady() {
        guard let status = exitStatus, outputSource == nil, errorSource == nil else { return }
        if let reason = stopReason {
            switch reason {
            case .cancelled: finish(.failure(CancellationError()))
            case .timedOut: finish(.failure(MetatronError.toolTimedOut(tool.lastPathComponent)))
            }
        } else if status == 0 { finish(.success(String(decoding: output, as: UTF8.self))) }
        else {
            let message = String(decoding: errors, as: UTF8.self).split(separator: "\n").suffix(2).joined(separator: " ")
            let fallback = status == -1 ? "No se pudo obtener el estado del proceso." : "El proceso terminó con estado \(status)."
            finish(.failure(MetatronError.toolFailed(tool.lastPathComponent, message.isEmpty ? fallback : message)))
        }
    }

    private func finish(_ result: Result<String, Error>) {
        guard !finished else { return }
        finished = true
        timeoutWork?.cancel(); timeoutWork = nil; killWork?.cancel(); killWork = nil
        outputSource?.cancel(); outputSource = nil; errorSource?.cancel(); errorSource = nil
        exitSource?.cancel(); exitSource = nil
        let waiting = continuation; continuation = nil
        waiting?.resume(with: result)
    }

    private func posixError(_ code: Int32) -> Error {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSLocalizedDescriptionKey: "\(tool.lastPathComponent): \(String(cString: strerror(code)))"])
    }
}
