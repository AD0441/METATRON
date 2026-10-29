import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Tools live on the second page of the ring (tap the trigger key again to switch).
public enum ToolID: String, CaseIterable, Sendable, Codable, Hashable {
    // Images
    case compress, resize, crop, addBackground, removeBackground, rotate, flip, grayscale, stripMetadata, extractText
    // PDFs
    case merge, split, rotatePDF, protect, compressPDF, extractPDFText, longImage
    // Video
    case compressVideo, mute, frames
    case transcribeAudio
    // Any file
    case zip, extract

    /// Tools that need a small window to collect settings first.
    public var needsEditor: Bool {
        switch self {
        case .crop, .addBackground, .resize, .protect: return true
        default: return false
        }
    }

    /// SF Symbol shown on the ring.
    public var symbol: String {
        switch self {
        case .compress, .compressPDF, .compressVideo: return "arrow.down.right.and.arrow.up.left"
        case .resize: return "arrow.up.left.and.down.right.magnifyingglass"
        case .crop: return "crop"
        case .addBackground: return "photo.on.rectangle.angled"
        case .removeBackground: return "person.crop.rectangle.badge.plus"
        case .rotate, .rotatePDF: return "rotate.right"
        case .flip: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .grayscale: return "circle.lefthalf.filled"
        case .stripMetadata: return "location.slash"
        case .extractText, .extractPDFText: return "text.viewfinder"
        case .merge: return "doc.on.doc"
        case .split: return "scissors"
        case .protect: return "lock.doc"
        case .mute: return "speaker.slash"
        case .longImage: return "rectangle.portrait.on.rectangle.portrait"
        case .frames: return "film.stack"
        case .transcribeAudio: return "waveform.and.mic"
        case .zip: return "doc.zipper"
        case .extract: return "archivebox"
        }
    }
}

/// One slice of the ring.
public enum KQAction: Hashable, Sendable, Codable {
    case convert(OutputFormat)
    case tool(ToolID)

    /// Stable identifier, used to store which slices the user turned off.
    public var id: String {
        switch self {
        case .convert(let f): return "convert.\(f.rawValue)"
        case .tool(let t): return "tool.\(t.rawValue)"
        }
    }

    public var symbol: String {
        switch self {
        case .tool(let t): return t.symbol
        case .convert(let f):
            switch f {
            case .pdf: return "doc.richtext"
            case .docx, .rtf, .odt: return "doc.text"
            case .txt, .md: return "text.alignleft"
            case .html: return "chevron.left.forwardslash.chevron.right"
            case .epub: return "book"
            case .pptx: return "rectangle.on.rectangle"
            case .csv, .tsv, .xlsx: return "tablecells"
            case .json, .plist: return "curlybraces"
            case .srt, .vtt: return "captions.bubble"
            case .mp4, .mov, .m4v, .webm, .mkv, .avi: return "film"
            case .gif: return "sparkles.rectangle.stack"
            case .m4a, .mp3, .wav, .aiff, .flac, .ogg, .opus, .caf: return "waveform"
            case .ico, .icns: return "app.dashed"
            case .zip, .tgz: return "doc.zipper"
            default: return "photo"
            }
        }
    }
}

/// Which actions make sense for a group of files.
public enum ActionCatalog {
    public static func convertActions(for urls: [URL], engines: Engines = .current, includeCurrentFormat: Bool = false) -> [KQAction] {
        guard let first = urls.first else { return [] }
        let targets = urls.map { formats(for: $0, engines: engines) }
        var common = targets[0].filter { format in targets.dropFirst().allSatisfy { $0.contains(format) } }
        // Combining images and existing PDFs is a group operation that preserves
        // PDF pages; it is not PDF -> PDF re-encoding through the document writer.
        if urls.count > 1, canMerge(urls), !common.contains(.pdf) { common.append(.pdf) }
        return common.filter { includeCurrentFormat || urls.count > 1 || !$0.matches(first) }.map { .convert($0) }
    }

    private static func formats(for first: URL, engines: Engines) -> [OutputFormat] {
        let kind = FileKind.of(first)
        let ffmpeg = engines.ffmpeg != nil, office = engines.soffice != nil
        let ext = first.pathExtension.lowercased()
        var formats: [OutputFormat]
        switch kind {
        case .image:
            guard canReadImage(first) else { return [] }
            let preferred: [OutputFormat] = [.jpg, .png, .heic, .pdf, .md, .webp, .avif, .tiff, .gif, .bmp, .ico, .icns, .psd]
            formats = preferred.filter { $0 == .pdf || $0 == .md || ($0 == .webp && engines.canWriteWebP) || OutputFormat.writableImageFormats.contains($0) }
        case .pdf:
            formats = [.jpg, .png, .md, .docx, .txt, .epub, .rtf, .tiff, .html]
        case .document:
            formats = [.pdf, .md, .docx, .epub, .txt, .rtf, .html, .odt]
        case .ebook:
            formats = [.pdf, .docx, .txt, .html, .rtf]
        case .data:
            switch ext {
            case "json": formats = [.md, .csv, .xlsx, .tsv, .plist, .html, .pdf]
            case "plist": formats = [.md, .json, .csv, .xlsx]
            default: formats = [.md, .xlsx, .csv, .json, .tsv, .html, .pdf]
            }
        case .office:
            guard office else { return [] }
            switch ext {
            case "xls", "ods", "numbers": formats = [.pdf, .xlsx, .csv, .html]
            case "ppt", "odp", "key": formats = [.pdf, .pptx]
            case "pptx": formats = [.pdf]
            default: formats = [.pdf, .docx, .txt]
            }
        case .subtitle:
            formats = [.srt, .vtt, .txt, .md]
        case .video:
            let native = FileKind.isNativeMedia(first)
            guard native || ffmpeg else { return [] }
            formats = [.mp4, .mov, .gif, .m4a]
            if ffmpeg { formats += [.mp3, .webm, .mkv, .avi] }
            formats.append(.m4v)
        case .audio:
            guard FileKind.isNativeMedia(first) || ffmpeg else { return [] }
            formats = ffmpeg ? [.mp3, .m4a, .wav, .flac, .aiff, .ogg, .opus, .caf] : [.m4a, .wav, .aiff, .flac, .caf]
            if AppleSpeech.isSupported { formats = [.txt, .md] + formats }
        case .archive:
            formats = [.zip, .tgz]
        case .folder, .other:
            formats = []
        }
        return formats
    }

    public static func toolActions(for urls: [URL], engines: Engines = .current) -> [KQAction] {
        guard let first = urls.first else { return [] }
        let candidates = tools(for: first, engines: engines)
        var common = candidates.filter { tool in urls.dropFirst().allSatisfy { tools(for: $0, engines: engines).contains(tool) } }
        if urls.count > 1, canMerge(urls) { common.insert(.merge, at: 0) }
        return common.map { .tool($0) }
    }
    private static func tools(for url: URL, engines: Engines) -> [ToolID] {
        switch FileKind.of(url) {
        case .image:
            guard canReadImage(url) else { return [.zip] }
            var tools: [ToolID] = [.compress, .resize, .crop, .addBackground, .removeBackground, .stripMetadata, .extractText, .rotate, .flip, .grayscale, .zip]
            // Metadata stripping preserves the source container; read-only ImageIO
            // formats cannot be written back by that operation.
            if !canRewriteImage(url) { tools.removeAll { $0 == .stripMetadata } }
            return tools
        case .pdf: return [.compressPDF, .split, .rotatePDF, .protect, .extractPDFText, .longImage, .zip]
        case .video:
            return FileKind.isNativeMedia(url) || engines.ffmpeg != nil ? [.compressVideo, .mute, .frames, .zip] : [.zip]
        case .audio:
            return AppleSpeech.isSupported && (FileKind.isNativeMedia(url) || engines.ffmpeg != nil) ? [.transcribeAudio, .zip] : [.zip]
        case .archive: return [.extract, .zip]
        default: return [.zip]
        }
    }
    /// The same capability rules protect execution and recipe projections. Same
    /// format conversions are valid in chains (resize PNG -> encode PNG again).
    public static func supports(_ action: KQAction, for urls: [URL], engines: Engines = .current) -> Bool {
        guard !urls.isEmpty else { return false }
        if action == .tool(.merge) { return canMerge(urls) }
        switch action {
        case .convert: return convertActions(for: urls, engines: engines, includeCurrentFormat: true).contains(action)
        case .tool: return toolActions(for: urls, engines: engines).contains(action)
        }
    }

    private static let readableImageTypes = Set((CGImageSourceCopyTypeIdentifiers() as? [String]) ?? [])
    private static let writableImageTypes = Set((CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? [])
    private static func canRewriteImage(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return writableImageTypes.contains(type.identifier)
    }
    private static func canReadImage(_ url: URL) -> Bool {
        // SVG is rasterized by Images.loadSVG through AppKit, outside ImageIO.
        if url.pathExtension.lowercased() == "svg" { return true }
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return readableImageTypes.contains(type.identifier)
    }
    private static func canMerge(_ urls: [URL]) -> Bool {
        urls.allSatisfy { FileKind.of($0) == .pdf || (FileKind.of($0) == .image && canReadImage($0)) }
    }

    /// Every action that can ever appear for a kind (for Settings and watch folders).
    public static func allActions(for kind: FileKind) -> (convert: [KQAction], tools: [KQAction]) {
        let everything = Engines(ffmpeg: URL(fileURLWithPath: "/ffmpeg"), soffice: URL(fileURLWithPath: "/soffice"), cwebp: URL(fileURLWithPath: "/cwebp"))
        let samples: [URL]
        switch kind {
        case .image: samples = [URL(fileURLWithPath: "/tmp/a.png"), URL(fileURLWithPath: "/tmp/b.webp")]
        case .pdf: samples = [URL(fileURLWithPath: "/tmp/a.pdf"), URL(fileURLWithPath: "/tmp/b.pdf")]
        case .document: samples = [URL(fileURLWithPath: "/tmp/a.md")]
        case .ebook: samples = [URL(fileURLWithPath: "/tmp/a.epub")]
        case .data: samples = ["csv", "json", "plist"].map { URL(fileURLWithPath: "/tmp/sample." + $0) }
        case .office: samples = ["xls", "ppt", "pages"].map { URL(fileURLWithPath: "/tmp/sample." + $0) }
        case .subtitle: samples = [URL(fileURLWithPath: "/tmp/a.ass.srt"), URL(fileURLWithPath: "/tmp/b.vtt")]
        case .video: samples = [URL(fileURLWithPath: "/tmp/a.flv")]
        case .audio: samples = [URL(fileURLWithPath: "/tmp/a.wma")]
        case .archive: samples = [URL(fileURLWithPath: "/tmp/a.rar")]
        case .folder, .other: samples = [URL(fileURLWithPath: "/tmp/folder/", isDirectory: true)]
        }
        // Settings describe a family, so use the union of its subtypes rather
        // than the intersection used for an actual multi-file selection.
        var conversions: [KQAction] = [], tools: [KQAction] = []
        for sample in samples {
            for action in convertActions(for: [sample], engines: everything, includeCurrentFormat: true) where !conversions.contains(action) { conversions.append(action) }
            for action in toolActions(for: [sample], engines: everything) where !tools.contains(action) { tools.append(action) }
        }
        for action in convertActions(for: samples, engines: everything) where !conversions.contains(action) { conversions.append(action) }
        for action in toolActions(for: samples, engines: everything) where !tools.contains(action) { tools.append(action) }
        return (conversions, tools)
    }
}
