import Foundation
import CoreGraphics
import ImageIO
import MetatronCore

/// Exports embedded raster XObjects, independently of the page previews.
/// Unsupported masks and colour spaces remain in the original PDF and are reported.
public enum PDFEmbeddedImages {
    public struct Report:Codable,Sendable {public let extracted:Int;public let skipped:Int}
    public static func extract(_ input:URL,into directory:URL) throws ->Report {
        guard let pdf=CGPDFDocument(input as CFURL),!pdf.isEncrypted || pdf.isUnlocked else {throw WorkflowError.invalid("No se pudo abrir el PDF para extraer imágenes.")}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let collector=Collector(directory:directory)
        for page in 1...max(1,pdf.numberOfPages) {
            try Task.checkCancellation()
            guard let dictionary=pdf.page(at:page)?.dictionary else {continue}
            collector.page=page;collector.scan(dictionary)
            if let error=collector.error {throw error}
        }
        let report=Report(extracted:collector.extracted,skipped:collector.skipped)
        try JSONEncoder().encode(report).write(to:directory.appendingPathComponent("extraccion.json"))
        return report
    }
    private final class Collector {
        let directory:URL
        var page=0,extracted=0,skipped=0,depth=0
        var error:Error?
        var colorSpaces:CGPDFDictionaryRef?
        init(directory:URL) {self.directory=directory}
        func scan(_ dictionary:CGPDFDictionaryRef) {
            guard depth<8,extracted<100 else {skipped += 1;return}
            var resources:CGPDFDictionaryRef?,objects:CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(dictionary,"Resources",&resources),let resources,
                  CGPDFDictionaryGetDictionary(resources,"XObject",&objects),let objects else {return}
            let previous=colorSpaces
            var pageSpaces:CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(resources,"ColorSpace",&pageSpaces) {colorSpaces=pageSpaces}
            depth += 1;defer {depth -= 1;colorSpaces=previous}
            CGPDFDictionaryApplyFunction(objects,{ _,object,info in
                guard let info else {return}
                let collector=Unmanaged<Collector>.fromOpaque(info).takeUnretainedValue()
                guard collector.error == nil else {return}
                do {try collector.consume(object)} catch {collector.error=error}
            },Unmanaged.passUnretained(self).toOpaque())
        }
        private func integer(_ dictionary:CGPDFDictionaryRef,_ key:String)->Int {
            var number:CGPDFInteger=0
            return CGPDFDictionaryGetInteger(dictionary,key,&number) ? number : 0
        }
        private func name(_ dictionary:CGPDFDictionaryRef,_ key:String)->String {
            var name:UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(dictionary,key,&name),let name else {return ""}
            return String(cString:name)
        }
        private func space(_ dictionary:CGPDFDictionaryRef)->CGColorSpace? {
            let value=name(dictionary,"ColorSpace")
            switch value {
            case "DeviceRGB":return CGColorSpaceCreateDeviceRGB()
            case "DeviceGray":return CGColorSpaceCreateDeviceGray()
            case "DeviceCMYK":return CGColorSpaceCreateDeviceCMYK()
            default:break
            }
            var array:CGPDFArrayRef?
            if !CGPDFDictionaryGetArray(dictionary,"ColorSpace",&array),let colorSpaces,!value.isEmpty {
                _=CGPDFDictionaryGetArray(colorSpaces,value,&array)
            }
            guard let array else {return nil}
            var type:UnsafePointer<CChar>?
            guard CGPDFArrayGetName(array,0,&type),let type,String(cString:type) == "ICCBased" else {return nil}
            var stream:CGPDFStreamRef?
            var format:CGPDFDataFormat = .raw
            guard CGPDFArrayGetStream(array,1,&stream),let stream,let profile=CGPDFStreamCopyData(stream,&format) else {return nil}
            return CGColorSpace(iccData:profile)
        }
        func consume(_ object:CGPDFObjectRef) throws {
            try Task.checkCancellation()
            var stream:CGPDFStreamRef?
            guard CGPDFObjectGetValue(object,.stream,&stream),let stream,let dictionary=CGPDFStreamGetDictionary(stream) else {return}
            if name(dictionary,"Subtype") == "Form" {scan(dictionary);return}
            guard name(dictionary,"Subtype") == "Image" else {return}
            let width=integer(dictionary,"Width"),height=integer(dictionary,"Height")
            guard extracted<100,width>0,height>0,width<=20_000,height<=20_000,Double(width)*Double(height)<=20_000_000 else {skipped += 1;return}
            var format:CGPDFDataFormat = .raw
            guard let data=CGPDFStreamCopyData(stream,&format) else {skipped += 1;return}
            let stem=String(format:"pagina-%03d-imagen-%03d",page,extracted+1)
            if format == .jpegEncoded || format == .JPEG2000 {
                guard let source=CGImageSourceCreateWithData(data,nil),CGImageSourceGetCount(source)>0 else {skipped += 1;return}
                try (data as Data).write(to:directory.appendingPathComponent(stem+(format == .jpegEncoded ? ".jpg" : ".jp2")))
            } else {
                guard let space=space(dictionary) else {skipped += 1;return}
                let components=space.numberOfComponents
                guard integer(dictionary,"BitsPerComponent") == 8,CFDataGetLength(data) == width*height*components,
                      let provider=CGDataProvider(data:data),let image=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:8*components,bytesPerRow:width*components,space:space,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.none.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent) else {skipped += 1;return}
                try Images.write(image,to:directory.appendingPathComponent(stem+".png"),format:.png,quality:1)
            }
            extracted += 1
        }
    }
}
