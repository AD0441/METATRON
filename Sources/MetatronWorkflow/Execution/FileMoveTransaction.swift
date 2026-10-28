import Foundation
import MetatronCore
public struct MovedFile: Codable, Sendable {
    public let original: URL
    public let destination: URL
    public let digest: String
}
public enum FileMoveTransaction {
    @concurrent public static func move(_ sources: [URL], into folder: URL) async throws -> [MovedFile] {
        let fm = FileManager.default
        guard (try? folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { throw WorkflowError.invalid("El destino no existe o no es una carpeta. Revísalo en Ajustes.") }
        let targetFolder = folder.resolvingSymlinksInPath().standardizedFileURL
        guard Set(sources.map(\.standardizedFileURL)).count == sources.count else { throw WorkflowError.invalid("Hay archivos repetidos en la selección.") }
        for source in sources {
            let resolved = source.resolvingSymlinksInPath().standardizedFileURL
            guard resolved.deletingLastPathComponent() != targetFolder else { throw WorkflowError.invalid("El archivo ya está en esa carpeta.") }
            guard !targetFolder.path.hasPrefix(resolved.path + "/"), targetFolder != resolved else { throw WorkflowError.invalid("Una carpeta no puede moverse dentro de sí misma.") }
        }
        var done: [MovedFile] = []
        do {
            for source in sources {
                try Task.checkCancellation()
                let hash = try FileIntegrity.digest(source)
                let destination = OutputPlanner.unique(folder.appendingPathComponent(source.lastPathComponent, isDirectory: source.hasDirectoryPath))
                guard source.standardizedFileURL != destination.standardizedFileURL else { throw WorkflowError.invalid("El archivo ya está en esa carpeta.") }
                try fm.moveItem(at: source, to: destination)
                done.append(MovedFile(original: source, destination: destination, digest: hash))
            }
            return done
        } catch { for record in done.reversed() { try? fm.moveItem(at: record.destination, to: record.original) }; throw error }
    }
    @concurrent public static func undo(_ records: [MovedFile]) async throws {
        let fm = FileManager.default
        for record in records {
            guard !fm.fileExists(atPath: record.original.path) else { throw WorkflowError.invalid("Ya existe un archivo en la ubicación original. Se conserva el movimiento.") }
            guard try FileIntegrity.digest(record.destination) == record.digest else { throw WorkflowError.changedOutput(record.destination.lastPathComponent) }
        }
        var done: [MovedFile] = []
        do {
            for record in records { try fm.moveItem(at: record.destination, to: record.original); done.append(record) }
        } catch { for record in done.reversed() { try? fm.moveItem(at: record.original, to: record.destination) }; throw error }
    }
}
