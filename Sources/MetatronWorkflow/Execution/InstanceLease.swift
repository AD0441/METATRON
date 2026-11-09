import Foundation
import Darwin

public enum InstanceLeaseError: LocalizedError, Equatable {
    case alreadyRunning, unavailable
    public var errorDescription: String? {
        switch self {
        case .alreadyRunning: "METATRON ya está abierto."
        case .unavailable: "No se pudo crear o bloquear el archivo de instancia. Revisa los permisos de Soporte de aplicaciones."
        }
    }
}
/// The immutable descriptor owns an advisory lock; the kernel releases it on exit or crash.
public final class InstanceLease: @unchecked Sendable {
    private let descriptor:Int32
    public init(url:URL) throws {
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let descriptor=Darwin.open(url.path,O_CREAT|O_RDWR|O_CLOEXEC,mode_t(0o600))
        guard descriptor >= 0 else {throw InstanceLeaseError.unavailable}
        guard flock(descriptor,LOCK_EX|LOCK_NB) == 0 else {
            let reason=errno
            Darwin.close(descriptor)
            throw reason == EWOULDBLOCK ? InstanceLeaseError.alreadyRunning : InstanceLeaseError.unavailable
        }
        self.descriptor=descriptor
    }
    deinit {flock(descriptor,LOCK_UN);Darwin.close(descriptor)}
}
