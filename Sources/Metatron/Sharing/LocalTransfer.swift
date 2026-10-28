import Foundation
import Network
import Observation
import MetatronWorkflow

/// Explicit, short-lived LAN sharing of one selected file. No directory browsing or uploads.
@Observable @MainActor final class LocalTransfer {
    var link: String?
    var status = "Comparte un archivo durante diez minutos"
    @ObservationIgnored private var listener: NWListener?
    @ObservationIgnored private var expiration: Task<Void, Never>?
    @ObservationIgnored private var connections: [UUID: NWConnection] = [:]
    @ObservationIgnored private var source: URL?
    @ObservationIgnored private var token = UUID().uuidString
    func start(_ file: URL) {
        stop()
        guard (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { status = "Comparte un archivo individual. Para carpetas, crea antes un ZIP."; return }
        source = file; token = UUID().uuidString
        do {
            let listener = try NWListener(using: .tcp, on: .any)
            self.listener = listener
            let sessionToken = token
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self, self.token == sessionToken else { return }
                    switch state {
                    case .ready:
                        guard let port = self.listener?.port?.rawValue else { return }
                        self.link = "http://\(Self.address()):\(port)/\(self.token)"
                        self.status = "Enlace activo · acceso al archivo seleccionado"
                    case .failed(let error): self.status = error.localizedDescription; self.stop()
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in Task { @MainActor in self?.accept(connection) } }
            listener.start(queue: .global(qos: .utility))
            expiration = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(600)) } catch { return }
                self?.stop()
            }
        } catch { status = error.localizedDescription }
    }
    func stop() {
        expiration?.cancel(); expiration = nil
        listener?.cancel(); listener = nil
        connections.values.forEach { $0.cancel() }; connections = [:]
        link = nil; source = nil; token = UUID().uuidString
    }
    private func accept(_ connection: NWConnection) {
        guard connections.count < 4 else { connection.cancel(); return }
        let id = UUID(); connections[id] = connection
        connection.start(queue: .global(qos: .utility))
        readRequest(connection, id: id, accumulated: Data())
    }
    private func readRequest(_ connection: NWConnection, id: UUID, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, complete, error in
            Task { @MainActor in
                guard let self else { connection.cancel(); return }
                var request = accumulated; request.append(data ?? Data())
                if request.count > 8192 || error != nil { self.finish(id); return }
                let text = String(decoding: request, as: UTF8.self)
                if !text.contains("\r\n\r\n"), !complete { self.readRequest(connection, id: id, accumulated: request); return }
                guard text.hasPrefix("GET /\(self.token) HTTP/"), let source = self.source else {
                    connection.send(content: Data("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8), completion: .contentProcessed { _ in connection.cancel() })
                    self.connections.removeValue(forKey: id); return
                }
                Task {
                    do { try await Self.transfer(source, over: connection) }
                    catch { self.status = "Transferencia detenida: \(error.localizedDescription)" }
                    self.finish(id)
                }
            }
        }
    }
    private func finish(_ id: UUID) { connections.removeValue(forKey: id)?.cancel() }
    @concurrent private static func transfer(_ file: URL, over connection: NWConnection) async throws {
        let handle = try FileHandle(forReadingFrom: file); defer { try? handle.close() }
        let size = try handle.seekToEnd(); try handle.seek(toOffset: 0)
        let ext = file.pathExtension.filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        let header = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Disposition: attachment; filename=\"metatron.\(ext)\"\r\nContent-Length: \(size)\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n"
        try await send(Data(header.utf8), to: connection)
        while let chunk = try handle.read(upToCount: 65_536), !chunk.isEmpty {
            try Task.checkCancellation(); try await send(chunk, to: connection)
        }
    }
    private static func send(_ data: Data, to connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in if let error { continuation.resume(throwing: error) } else { continuation.resume() } })
        }
    }
    private static func address() -> String {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0 else { return ProcessInfo.processInfo.hostName }
        defer { freeifaddrs(head) }
        var cursor = head
        while let current = cursor {
            defer { cursor = current.pointee.ifa_next }
            guard let address = current.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: current.pointee.ifa_name)
            guard name.hasPrefix("en") else { continue }
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(address, socklen_t(MemoryLayout<sockaddr_in>.size), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 { return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self) }
        }
        return ProcessInfo.processInfo.hostName
    }
}
