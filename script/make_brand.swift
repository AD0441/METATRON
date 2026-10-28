import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let assets = root.appendingPathComponent("docs/assets/brand", isDirectory:true)
let iconset = root.appendingPathComponent("Resources/Metatron.iconset",isDirectory:true)
try FileManager.default.createDirectory(at: assets,withIntermediateDirectories:true)
try FileManager.default.createDirectory(at: iconset,withIntermediateDirectories:true)
let navy=NSColor(srgbRed:0.065,green:0.105,blue:0.15,alpha:1)
let ivory=NSColor(srgbRed:0.91,green:0.90,blue:0.85,alpha:1)
let teal=NSColor(srgbRed:0.50,green:0.70,blue:0.77,alpha:1)
func centers(_ center:NSPoint,_ r:CGFloat)->[NSPoint] {
 [center] + [1.0,0.5].flatMap { multiplier in (0..<6).map { i in let a=Double(i)*Double.pi/3-Double.pi/2;return NSPoint(x:center.x+cos(a)*r*multiplier,y:center.y+sin(a)*r*multiplier) } }
}
func symbol(center:NSPoint,radius:CGFloat,color:NSColor,simple:Bool=false) {
 let all=centers(center,radius), points=simple ? Array(all.prefix(7)) : all
 let path=NSBezierPath();path.lineWidth=max(0.5,radius*0.013)
 for a in 0..<points.count { for b in (a+1)..<points.count {path.move(to:points[a]);path.line(to:points[b])} }
 color.withAlphaComponent(simple ? 0.7 : 0.42).setStroke();path.stroke()
 color.setStroke()
 for p in points {let circle=NSBezierPath(ovalIn:NSRect(x:p.x-radius*0.25,y:p.y-radius*0.25,width:radius*0.5,height:radius*0.5));circle.lineWidth=max(0.7,radius*0.025);circle.stroke()}
}
func bitmap(_ size:NSSize,_ file:URL,draw:()->Void)throws {
 let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:Int(size.width),pixelsHigh:Int(size.height),bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep);draw();NSGraphicsContext.restoreGraphicsState()
 try rep.representation(using:.png,properties:[:])!.write(to:file)
}
for side in [16,32,64,128,256,512,1024] {
 let temp=assets.appendingPathComponent("icon-\(side).png")
 try bitmap(NSSize(width:side,height:side),temp) {
  let scale=CGFloat(side)/1024;let t=NSAffineTransform();t.scale(by:scale);t.concat()
  navy.setFill();NSBezierPath(roundedRect:NSRect(x:48,y:48,width:928,height:928),xRadius:210,yRadius:210).fill()
  symbol(center:NSPoint(x:512,y:512),radius:310,color:ivory,simple:side<=32)
 }
 if side<=512 {try Data(contentsOf:temp).write(to:iconset.appendingPathComponent("icon_\(side)x\(side).png"))}
 if side>=32 {try Data(contentsOf:temp).write(to:iconset.appendingPathComponent("icon_\(side/2)x\(side/2)@2x.png"))}
 if side==1024 {try Data(contentsOf:temp).write(to:assets.appendingPathComponent("app-icon.png"))}
 try FileManager.default.removeItem(at:temp)
}
try bitmap(NSSize(width:1024,height:1024),assets.appendingPathComponent("symbol-light.png")) { symbol(center:NSPoint(x:512,y:512),radius:380,color:navy) }
try bitmap(NSSize(width:1024,height:1024),assets.appendingPathComponent("symbol-dark.png")) { symbol(center:NSPoint(x:512,y:512),radius:380,color:ivory) }
func text(_ value:String,_ point:NSPoint,_ size:CGFloat,_ weight:NSFont.Weight,_ color:NSColor,kern:CGFloat=0) {
 (value as NSString).draw(at:point,withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:weight),.foregroundColor:color,.kern:kern])
}
try bitmap(NSSize(width:1600,height:800),assets.appendingPathComponent("cover.png")) {
 navy.setFill();NSRect(x:0,y:0,width:1600,height:800).fill()
 symbol(center:NSPoint(x:1220,y:424),radius:235,color:teal)
 text("METATRON",NSPoint(x:82,y:578),81,.semibold,ivory,kern:8)
 text("Ordena tus archivos.",NSPoint(x:85,y:414),48,.medium,ivory)
 text("Recupera tu tiempo.",NSPoint(x:85,y:351),48,.medium,ivory)
 text("Convierte · organiza · automatiza",NSPoint(x:87,y:279),25,.regular,teal)
 let line=NSBezierPath();line.move(to:NSPoint(x:86,y:191));line.line(to:NSPoint(x:1514,y:191));line.lineWidth=1;ivory.withAlphaComponent(0.18).setStroke();line.stroke()
 text("NATIVO PARA macOS",NSPoint(x:87,y:128),16,.semibold,ivory,kern:2)
 text("SwiftUI  /  Apple Silicon  /  Procesamiento local",NSPoint(x:87,y:86),20,.regular,teal)
 text("Creado por Sebastián Pastén F.",NSPoint(x:1100,y:90),18,.regular,ivory)
}
print(assets.path)
