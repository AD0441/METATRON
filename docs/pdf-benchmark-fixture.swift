import Foundation
import CoreGraphics
var box = CGRect(x: 0, y: 0, width: 612, height: 792)
let context = CGContext(URL(fileURLWithPath: "/private/tmp/citrino-performance.pdf") as CFURL, mediaBox: &box, nil)!
for page in 0..<24 {
 context.beginPDFPage(nil)
 context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(box)
 for line in 0..<45 {
  context.setFillColor(CGColor(gray: CGFloat((line + page) % 7) / 9, alpha: 1))
  context.fill(CGRect(x: 40, y: 40 + line * 15, width: 480 - line % 6 * 20, height: 5))
 }
 context.endPDFPage()
}
context.closePDF()
