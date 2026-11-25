import AppKit
import PDFKit
import WebKit

/// Uses macOS's Office preview so tables, shading and header images survive export.
/// The preview is generated locally and rendered with network access disabled.
enum OfficePreviewPDF {
    @MainActor static func convert(_ input: URL, to output: URL) async throws {
        let work = FileManager.default.temporaryDirectory.appendingPathComponent("metatron-office-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: work) }
        try await Engines.run(URL(fileURLWithPath: "/usr/bin/qlmanage"), ["-p", "-o", work.path, input.path], timeout: 60)
        let preview = work.appendingPathComponent(input.lastPathComponent + ".qlpreview", isDirectory: true)
        let html = preview.appendingPathComponent("Preview.html")
        guard FileManager.default.fileExists(atPath: html.path) else {
            throw MetatronError.badData("macOS no pudo preparar el diseño de este documento para PDF.")
        }
        var attributes: NSDictionary?
        _ = try NSAttributedString(url: input, options: [:], documentAttributes: &attributes)
        let paper = (attributes?[NSAttributedString.DocumentAttributeKey.paperSize] as? NSValue)?.sizeValue ?? NSSize(width: 595.3, height: 841.9)
        guard paper.width.isFinite, paper.height.isFinite, paper.width >= 72, paper.height >= 72,
              paper.width <= 14_400, paper.height <= 14_400 else {
            throw MetatronError.badData("El tamaño de página del documento no es válido.")
        }
        // Quick Look adds viewport padding/minimum height for its viewer. Let the
        // actual content determine page breaks instead of exporting that padding.
        var source = try String(contentsOf: html, encoding: .utf8)
        source = source.replacingOccurrences(of: #"min-height:\s*[0-9.]+(?:px|pt)?\s*;"#, with: "", options: .regularExpression)
        source = source.replacingOccurrences(of: "</head>", with: "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src file: data:; style-src 'unsafe-inline'; font-src file: data:\"><style>body{margin:0!important;-webkit-print-color-adjust:exact;}</style></head>")
        try source.write(to: html, atomically: true, encoding: .utf8)
        let renderer = OfficeHTMLRenderer(paper: paper)
        try await renderer.write(html: html, to: output)
    }
}

@MainActor private final class OfficeHTMLRenderer: NSObject, WKNavigationDelegate {
    private let view: WKWebView
    private let paper: NSSize
    private var loaded = false
    private var loadError: Error?

    init(paper: NSSize) {
        self.paper = paper
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        view = WKWebView(frame: CGRect(origin: .zero, size: paper), configuration: configuration)
        super.init()
        view.navigationDelegate = self
    }

    func write(html: URL, to output: URL) async throws {
        defer { view.stopLoading(); view.navigationDelegate = nil }
        let rules = #"[{"trigger":{"url-filter":"^https?://"},"action":{"type":"block"}}]"#
        let blocker = try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "METATRONLocalOffice", encodedContentRuleList: rules)
        if let blocker { view.configuration.userContentController.add(blocker) }
        view.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        while !loaded {
            try Task.checkCancellation()
            if let loadError { throw loadError }
            guard ContinuousClock.now < deadline else { throw MetatronError.toolTimedOut("Vista previa de Office") }
            try await Task.sleep(for: .milliseconds(20))
        }
        // Break before a row, paragraph or image that would straddle the page.
        // Oversized blocks may span pages, ensuring progress without dropping text.
        let script = """
        await document.fonts.ready;
        const blocks = Array.from(document.querySelectorAll('tr,p,img')).map(e => {
            const r = e.getBoundingClientRect(); return [r.top + scrollY, r.bottom + scrollY];
        });
        const height = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
        const pages = [];
        let start = 0;
        while (start < height && pages.length < 500) {
            let end = Math.min(height, start + pageHeight);
            if (end < height) {
                const crossing = blocks.filter(([top,bottom]) => top > start + 1 && top < end && bottom > end && bottom - top <= pageHeight);
                if (crossing.length) end = Math.min(...crossing.map(b => b[0]));
            }
            pages.push([start,end]); start = end;
        }
        if (start < height) throw new Error('El documento supera el límite de 500 páginas.');
        return pages;
        """
        let result = try await view.callAsyncJavaScript(script, arguments: ["pageHeight": paper.height], in: nil, contentWorld: .defaultClient)
        guard let pages = result as? [[NSNumber]], !pages.isEmpty else { throw MetatronError.writeFailed(output) }
        var box = CGRect(origin: .zero, size: paper)
        guard let context = CGContext(output as CFURL, mediaBox: &box, nil) else { throw MetatronError.writeFailed(output) }
        defer { context.closePDF() }
        for bounds in pages {
            try Task.checkCancellation()
            guard bounds.count == 2 else { throw MetatronError.writeFailed(output) }
            let top = bounds[0].doubleValue, height = bounds[1].doubleValue - top
            let configuration = WKPDFConfiguration()
            configuration.rect = CGRect(x: 0, y: top, width: paper.width, height: height)
            let data = try await view.pdf(configuration: configuration)
            guard let provider = CGDataProvider(data: data as CFData),
                  let pdf = CGPDFDocument(provider), let page = pdf.page(at: 1) else { throw MetatronError.writeFailed(output) }
            context.beginPDFPage(nil)
            context.saveGState()
            context.translateBy(x: 0, y: paper.height - height)
            context.drawPDFPage(page)
            context.restoreGState()
            context.endPDFPage()
        }
        try Task.checkCancellation()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loaded = true }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { loadError = error }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { loadError = error }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadError = MetatronError.badData("Se interrumpió el renderizado del documento. Vuelve a intentarlo.")
    }
}
