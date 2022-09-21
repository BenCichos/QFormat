//
//  QOI+Constants.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation


final public class QOICoder {
    static private let QOI_OP_INDEX : UInt8 = 0x00
    static private let QOI_OP_DIFF : UInt8 = 0x40
    static private let QOI_OP_LUMA : UInt8 = 0x80
    static private let QOI_OP_RUN  : UInt8 = 0xc0
    static private let QOI_OP_RGB : UInt8 = 0xfe
    static private let QOI_OP_RGBA : UInt8 = 0xff
    static private let QOI_MASK_2 : UInt8 = 0xc0
    static private let QOI_HEADER_SIZE : UInt8 = 14
    static private let QOI_MAGIC : UInt32 = UInt32("q") << 24 | UInt32("o") << 16 | UInt32("i") << 8 | UInt32("f")
    static private let QOI_PIXEL_MAX : UInt32 = UInt32(400000000)
    static private let QOI_PADDING : Array<UInt8> = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
    static private let QOI_PADDING_SIZE : UInt8 = 0x08

    private struct QOIPixel: Equatable {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
        
        static func ==(lhs : QOIPixel, rhs : QOIPixel) -> Bool {
            return (lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a)
        }
    }
    
    struct QOIHeader {
        var width : UInt32
        var height : UInt32
        var channels : UInt8
        var colorspace : QOIColorSpace
    }

    enum QOIColorSpace : UInt8 {
        case Linear = 0x00
        case SRGB = 0x01
    }
    
    static func decode(_ data: UnsafeMutableBufferPointer<UInt8>) -> (QOIHeader?, Data?) {
        
        guard var pointer = data.baseAddress else { return (nil, nil)}
        let qoimagic : UInt32 = read4bytes(&pointer)

        
        guard qoimagic == QOI_MAGIC else { return (nil, nil) }

        
        let header : QOIHeader = QOIHeader(width: read4bytes(&pointer),
                                           height: read4bytes(&pointer),
                                           channels: readbyte(&pointer),
                                           colorspace: QOIColorSpace(rawValue: readbyte(&pointer))!)

        if (
            header.width == 0 || header.height == 0 ||
            header.channels < 3 || header.channels > 4 ||
            header.colorspace.rawValue > 1 || header.height >= QOI_PIXEL_MAX / header.width
        ) {
            return (nil, nil)
        }
        
        let noPixels : Int = Int(header.height * header.width)
        let noValues : Int = Int(noPixels) * 4
        var bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: noValues)
        let bytesBaseAddress = bytes
        var index : Array<QOIPixel> = Array(repeating: QOIPixel(r: 0x00, g: 0x00, b: 0x00, a: 0x00), count: 64)

        var px : QOIPixel = QOIPixel(r: 0x00, g: 0x00, b: 0x00, a: 0xff)
        let size : Int = noValues - Int(QOI_PADDING_SIZE)
        var run : UInt8 = 0x00
        
        for _ in 0..<noPixels {
            if run > 0x00 {
                run -= 0x01
            } else if (bytesBaseAddress.distance(to: bytes) < size){
                let b1 : UInt8 = readbyte(&pointer)
                if b1 == QOI_OP_RGB {
                    px = QOIPixel(r: readbyte(&pointer),
                                  g: readbyte(&pointer),
                                  b: readbyte(&pointer),
                                  a: px.a)
                } else if b1 == QOI_OP_RGBA  {
                    px = QOIPixel(r: readbyte(&pointer),
                                  g: readbyte(&pointer),
                                  b: readbyte(&pointer),
                                  a: readbyte(&pointer))
                } else if (b1 & QOI_MASK_2) == QOI_OP_INDEX {
                    px = index[Int(b1)]
                } else if (b1 & QOI_MASK_2) == QOI_OP_DIFF {
                    let dr = UInt8(truncatingIfNeeded: Int(px.r) + Int((b1 >> 0x04) & 0x03) - Int(0x02))
                    let dg = UInt8(truncatingIfNeeded: Int(px.g) + Int((b1 >> 0x02) & 0x03) - Int(0x02))
                    let db = UInt8(truncatingIfNeeded: Int(px.b) + Int(b1 & 0x03) - Int(0x02))
                    px = QOIPixel(r: dr, g: dg, b: db, a: px.a)
                } else if (b1 & QOI_MASK_2) == QOI_OP_LUMA {
                    let b2 = readbyte(&pointer)
                    let vg = Int(b1 & 0x3f) - Int(0x20)
                    let r = UInt8(truncatingIfNeeded: Int(px.r) + vg - 0x08 + Int((b2 >> 0x04) & 0x0f))
                    let g = UInt8(truncatingIfNeeded: Int(px.g) + vg)
                    let b = UInt8(truncatingIfNeeded: Int(px.b) + vg - 0x08 + Int(b2 & 0x0f))
                    px = QOIPixel(r: r, g: g, b: b, a: px.a)
                } else if (b1 & QOI_MASK_2) == QOI_OP_RUN {
                    run = b1 & 0x3f
                }
                index[Int(qoiHash(px) % 64)] = px
            }
            
            initialise(&bytes, px.r)
            initialise(&bytes, px.g)
            initialise(&bytes, px.b)
            initialise(&bytes, px.a)
        }
        
        let image = Data(bytesNoCopy: bytesBaseAddress, count: bytesBaseAddress.distance(to: bytes), deallocator: .free)
        
        return (header, image)
    }
    
    static func encode(_ data: UnsafeMutablePointer<UInt8>, _ header: QOIHeader?) -> Data? {
        
        guard let header = header else { return nil }
            
        if (header.width == 0 || header.height == 0 ||
            header.channels < 3 || header.channels > 4 ||
            header.colorspace.rawValue > 1 || header.height >= UInt32(QOI_PIXEL_MAX) / header.width
        ) {
            return nil
        }
        
        let maxsize = Int(header.width * header.height * (UInt32(header.channels) + 1) + UInt32(QOI_HEADER_SIZE) + UInt32(QOI_PADDING_SIZE))
        
        var pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxsize)
        let baseAddress = pointer
        
        var index : Array<QOIPixel> = Array<QOIPixel>(repeating: QOIPixel(r: 0x00, g: 0x00, b: 0x00, a: 0x00), count: 64)
        var run : UInt8 = 0x00
        var px_prev : QOIPixel = QOIPixel(r: 0x00, g: 0x00, b: 0x00, a: 0xff)
        var px : QOIPixel = px_prev
        
        initialise(&pointer, QOI_MAGIC)
        initialise(&pointer, header.width)
        initialise(&pointer, header.height)
        initialise(&pointer, header.channels)
        initialise(&pointer, header.colorspace.rawValue)
        
        let channels : Int = Int(header.channels)
        let px_len : Int = Int(header.width * header.height) * channels
        let px_end : Int = px_len - channels
        for px_pos in stride(from: 0, to: px_len, by: channels) {
            let r : UInt8 = data[px_pos]
            let g : UInt8 = data[px_pos + 1]
            let b : UInt8 = data[px_pos + 2]
            let a : UInt8 = header.channels == 0x04 ? data[px_pos + 3] : 0xff
            px = QOIPixel(r: r, g: g, b: b, a: a)
            
            if (px == px_prev) {
                run += 0x01
                if (run == 62 || px_pos == px_end) {
                    initialise(&pointer, QOI_OP_RUN | (run - 0x01))
                    run = 0x00
                }
            } else {
                if (run > 0x00) {
                    initialise(&pointer, QOI_OP_RUN | (run - 0x01))
                    run = 0x00
                }
                
                let index_pos = UInt8(qoiHash(px) % 64)
                if (index[Int(index_pos)] == px) {
                    initialise(&pointer, QOI_OP_INDEX | index_pos)
                } else {
                    index[Int(index_pos)] = px
                    
                    if (px.a == px_prev.a) {
                        let vr : Int8 = Int8(truncatingIfNeeded: px.r.subtractingReportingOverflow(px_prev.r).partialValue)
                        let vg : Int8 = Int8(truncatingIfNeeded: px.g.subtractingReportingOverflow(px_prev.g).partialValue)
                        let vb : Int8 = Int8(truncatingIfNeeded: px.b.subtractingReportingOverflow(px_prev.b).partialValue)
                        
                        let vg_r : Int8 = vr.subtractingReportingOverflow(vg).partialValue
                        let vg_b : Int8 = vb.subtractingReportingOverflow(vg).partialValue
                        
                        
                        if (
                            vr > -3 && vr < 2 &&
                            vg > -3 && vg < 2 &&
                            vb > -3 && vb < 2
                        ) {
                            initialise(&pointer, QOI_OP_DIFF | UInt8(vr + 0x02) << 4 | UInt8(vg + 0x02) << 2 | UInt8(vb + 0x02) )
                        } else if (
                            vg_r > -9 && vg_r < 8 &&
                            vg > -33 && vg < 32 &&
                            vg_b > -9 && vg_b < 8
                        ) {
                            initialise(&pointer, QOI_OP_LUMA | UInt8(vg + 0x20))
                            initialise(&pointer, UInt8(vg_r + 0x08) << 4 | UInt8(vg_b + 0x08))
                        } else {
                            initialise(&pointer, QOI_OP_RGB)
                            initialise(&pointer, px.r)
                            initialise(&pointer, px.g)
                            initialise(&pointer, px.b)
                        }
                    } else {
                        initialise(&pointer, QOI_OP_RGBA)
                        initialise(&pointer, px.r)
                        initialise(&pointer, px.g)
                        initialise(&pointer, px.b)
                        initialise(&pointer, px.a)
                    }
                }
            }
            px_prev = px
        }
        
        QOI_PADDING.forEach { x in
            initialise(&pointer, x)
        }
        
        let count = baseAddress.distance(to: pointer)
        
        return Data(bytesNoCopy: baseAddress, count: count, deallocator: .free)

    }

}

extension QOICoder {
    
    static private func qoiHash(_ pixel: QOIPixel) -> Int {
        let r : Int = Int(pixel.r) * 3
        let g : Int = Int(pixel.g) * 5
        let b : Int = Int(pixel.b) * 7
        let a : Int = Int(pixel.a) * 11
        
        return ( r + g + b + a)
    }
    
    static private func readbyte(_ pointer: inout UnsafeMutablePointer<UInt8>) -> UInt8 {
        let pointee = pointer.pointee
        pointer = pointer.successor()
        
        return pointee
    }

    static private func read4bytes(_ pointer: inout UnsafeMutablePointer<UInt8>) -> UInt32 {
        let a = UInt32(readbyte(&pointer))
        let b = UInt32(readbyte(&pointer))
        let c = UInt32(readbyte(&pointer))
        let d = UInt32(readbyte(&pointer))
        
        return (a << 24 | b << 16 | c << 8 | d)
    }

    static private func initialise(_ pointer: inout UnsafeMutablePointer<UInt8>,_ to: UInt32) {
        initialise(&pointer, UInt8((0xff000000 & to) >> 24))
        initialise(&pointer, UInt8((0x00ff0000 & to) >> 16))
        initialise(&pointer, UInt8((0x0000ff00 & to) >> 8))
        initialise(&pointer, UInt8((0x000000ff & to)))
    }

    static private func initialise(_ pointer: inout UnsafeMutablePointer<UInt8>, _ to: UInt8) {
        pointer.initialize(to: to)
        pointer = pointer.successor()
    }

}
