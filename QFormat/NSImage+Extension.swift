//
//  NSImage+Extension.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

extension NSImage {
    
    func asData() -> (UnsafeMutablePointer<UInt8>, Int, Int, Int)? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        
        let bytes = bitmap.bitmapData
        
        guard let bytes = bytes else { return nil }
    
        let size = bitmap.size
        let channels = bitmap.bitsPerPixel / 8
        let width : Int = Int(size.width)
        let height : Int = Int(size.height)
        
        return (bytes, width, height, channels)
        
    }
    
    
    convenience init?(image url: URL) {
        
        if UTType(filenameExtension: url.pathExtension) == UTType("com.QFormat.qoi") {
            do {
                let fileData = try Data(contentsOf: url)
                let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: fileData.count)
                let _ = fileData.copyBytes(to: buffer)
                let (header, bytes) = QOICoder.decode(buffer)
                buffer.deallocate()
                
                guard let bytes = bytes, let header = header else {
                    self.init()
                    return
                }

                let decodedWidth = Int(header.width)
                let decodedHeight = Int(header.height)
                let bytesPerRow = decodedWidth * 4
                let decodedSize = CGSize(width: decodedWidth, height: decodedHeight)
                let ciImage = CIImage(bitmapData: bytes,
                                      bytesPerRow: bytesPerRow,
                                      size: decodedSize,
                                      format: CIFormat.RGBA8,
                                      colorSpace: CGColorSpaceCreateDeviceRGB())
                            
                let context = CIContext()
                let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
                
                guard let cgImage = cgImage else {
                    self.init()
                    return
                }
                
                self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            } catch {
                self.init()
            }
            
        } else {
            self.init(contentsOf: url)
        }
        
    }
    
    
    func jpegData() -> Data? {
        let image = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmap = NSBitmapImageRep(cgImage: image)
        let data = bitmap.representation(using: .jpeg, properties: [:])
        return data
    }

    func pngData() -> Data? {
        let image = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmap = NSBitmapImageRep(cgImage: image)
        let data = bitmap.representation(using: .png, properties: [:])
        return data
    }
}
