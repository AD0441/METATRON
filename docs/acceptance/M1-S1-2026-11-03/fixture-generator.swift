import AppKit
import PDFKit
import ImageIO
import UniformTypeIdentifiers
import Metal

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let input = root.appendingPathComponent("input", isDirectory: true)
try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
func text(_ s: String, at p: CGPoint, size: CGFloat = 30) {
    (s as NSString).draw(at: p, withAttributes: [.font:NSFont.systemFont(ofSize:size),.foregroundColor:NSColor.black])
}
let canvas = NSImage(size:NSSize(width:1600,height:1000))
canvas.lockFocus()
NSColor.white.setFill();NSRect(x:0,y:0,width:1600,height:1000).fill()
NSColor.systemTeal.setFill();NSRect(x:80,y:80,width:600,height:400).fill()
text("METATRON M1 S1",at:CGPoint(x:100,y:800),size:64)
text("Prueba local. Reunión de mañana. Año 2026.",at:CGPoint(x:100,y:690),size:42)
canvas.unlockFocus()
var bounds = CGRect(x:0,y:0,width:1600,height:1000)
let image = canvas.cgImage(forProposedRect:&bounds,context:nil,hints:nil)!
for ext in ["png","jpg"] {
    let out = input.appendingPathComponent("imagen."+ext)
    let dest = CGImageDestinationCreateWithURL(out as CFURL, ext == "png" ? UTType.png.identifier as CFString : UTType.jpeg.identifier as CFString,1,nil)!
    let props:[CFString:Any] = [kCGImagePropertyOrientation:1,kCGImagePropertyExifDictionary:[kCGImagePropertyExifUserComment:"METATRON_SYNTHETIC_METADATA"],kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:1.0,kCGImagePropertyGPSLatitudeRef:"N",kCGImagePropertyGPSLongitude:1.0,kCGImagePropertyGPSLongitudeRef:"E"]]
    CGImageDestinationAddImage(dest,image,props as CFDictionary)
    precondition(CGImageDestinationFinalize(dest))
}
func makePDF(_ name:String,scan:Bool) throws {
    var box=CGRect(x:0,y:0,width:800,height:500)
    let c=CGContext(input.appendingPathComponent(name) as CFURL,mediaBox:&box,nil)!
    for page in 1...(scan ? 1 : 2) {
        c.beginPDFPage(nil)
        if scan {c.draw(image,in:box)}
        else {
            NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:false)
            text("METATRON página \(page)",at:CGPoint(x:60,y:380))
            text(page == 1 ? "Primera página: reunión y año 2026." : "Segunda página: información conservada.",at:CGPoint(x:60,y:300),size:24)
            NSGraphicsContext.restoreGraphicsState()
        }
        c.endPDFPage()
    }
    c.closePDF()
}
try makePDF("texto.pdf",scan:false);try makePDF("escaneado.pdf",scan:true)
let pd=PDFDocument(url:input.appendingPathComponent("texto.pdf"))!
precondition(pd.pageCount == 2 && (pd.string?.contains("Segunda") ?? false))
let scan=PDFDocument(url:input.appendingPathComponent("escaneado.pdf"))!
precondition((scan.string ?? "").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
let apps=NSRunningApplication.runningApplications(withBundleIdentifier:"local.metatron.app").map{["pid":$0.processIdentifier,"path":$0.bundleURL?.path ?? "", "policy":$0.activationPolicy.rawValue] as [String:Any]}
let info:[String:Any] = ["instances":apps,"metal":MTLCreateSystemDefaultDevice()?.name ?? "unavailable","os":ProcessInfo.processInfo.operatingSystemVersionString]
try JSONSerialization.data(withJSONObject:info,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("host.json"))
print(String(decoding:try JSONSerialization.data(withJSONObject:info),as:UTF8.self))
