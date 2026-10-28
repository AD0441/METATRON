import Foundation
import CryptoKit
import ImageIO
import PDFKit
import MetatronCore

public enum FileIntegrity {
    public static func digest(_ url: URL) throws -> String {
        let fm = FileManager.default
        if (try url.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink == true {
            throw WorkflowError.invalid("No se procesan enlaces simbólicos como resultados.")
        }
        if (try url.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true {
            let children = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).sorted { $0.lastPathComponent < $1.lastPathComponent }
            var hash = SHA256()
            for child in children { hash.update(data: Data((child.lastPathComponent + "\0" + (try digest(child))).utf8)) }
            return hash.finalize().map { String(format: "%02x", $0) }.joined()
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash = SHA256()
        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            try Task.checkCancellation()
            hash.update(data: chunk)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
    public static func bytes(_ url: URL) -> Int64 {
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            return ((try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []).reduce(0) { $0 + bytes($1) }
        }
        return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }
    public static func validate(_ url: URL, password: String? = nil) throws {
        guard FileManager.default.fileExists(atPath: url.path), bytes(url) > 0 else { throw WorkflowError.emptyResult }
        switch FileKind.of(url) {
        case .image:
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), CGImageSourceGetCount(source) > 0,
                  CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { throw WorkflowError.emptyResult }
        case .pdf:
            guard let pdf = PDFDocument(url: url) else { throw WorkflowError.emptyResult }
            if pdf.isLocked, let password { guard pdf.unlock(withPassword: password) else { throw WorkflowError.emptyResult } }
            guard pdf.pageCount > 0 else { throw WorkflowError.emptyResult }
        default: break
        }
    }
    public static func safeComponent(_ value: String) throws -> String {
        guard !value.isEmpty, value != ".", value != "..", !value.contains("/"), !value.contains(":"), !value.contains("\0") else {
            throw WorkflowError.invalid("El nombre de salida contiene caracteres no permitidos.")
        }
        return value
    }
    public static func unique(_ proposed: URL, reserved: inout Set<String>) -> URL {
        var candidate = proposed
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) || reserved.contains(candidate.path.lowercased()) {
            candidate = proposed.deletingLastPathComponent().appendingPathComponent(proposed.deletingPathExtension().lastPathComponent + " \(n)")
            if !proposed.pathExtension.isEmpty { candidate.appendPathExtension(proposed.pathExtension) }
            n += 1
        }
        reserved.insert(candidate.path.lowercased())
        return candidate
    }
}
