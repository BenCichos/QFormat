//
//  ImageInfoView.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

class ImageInfoView: NSView {
    @IBOutlet weak var exportImageBtn: RoundedButton!
    @IBOutlet weak var chooseExportFormatBtn: NSPopUpButton!
    @IBOutlet weak var gridView: NSGridView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gridView.wantsLayer = true
        gridView.column(at: 0).width = 90
        gridView.column(at: 1).width = 200
        
        
        chooseExportFormatBtn.addItem(withTitle: "Choose Export Format")
        chooseExportFormatBtn.item(at: 0)?.isEnabled = false
        chooseExportFormatBtn.addItem(withTitle: "QOI")
        chooseExportFormatBtn.addItem(withTitle: "PNG")
        chooseExportFormatBtn.addItem(withTitle: "JPEG")
        chooseExportFormatBtn.addItem(withTitle: "TIFF")
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(calibratedWhite: 0.6, alpha: 0.3).cgColor
        self.configureExportImageBtn()
    }
    
    
    func handleImageInfo(_ image: NSImage, file url: URL) {
        guard let image = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
                        
        
        for _ in 0..<self.gridView.numberOfRows {
            self.gridView.removeRow(at: 0)
        }
        
        self.gridView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        
        var size = 0
        var created = Date()
        var modified = Date()
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            size = attributes[FileAttributeKey.size] as? Int ?? 0
            created = attributes[FileAttributeKey.creationDate] as? Date ?? Date()
            modified = attributes[FileAttributeKey.modificationDate] as? Date ?? Date()
    
        } catch {
            print("Error")
        }
       
        var infoArray = Array<(String, String)>()
        
        infoArray.append(("Kind:", "\(UTType(filenameExtension: url.pathExtension)?.localizedDescription ?? "")"))
        infoArray.append(("Size:", "\(size.formatted()) bytes"))
        infoArray.append(("Where:","\(url.path)"))
        infoArray.append((("Created:", "\(created.formatted())")))
        infoArray.append(("Last Modified:", "\(modified.formatted())"))
        infoArray.append(("Width:", "\(image.width) pixels"))
        infoArray.append(("Height", "\(image.height) pixels"))
        infoArray.append(("Colour Profile:", "\(NSColorSpace(cgColorSpace: image.colorSpace!)?.localizedName ?? "")"))
        
        infoArray.forEach { (name, description) in
            let leftTextField = InfoTextField(name, .right)
            let righTextField = InfoTextField(description, .left)
            
            self.gridView.addRow(with: [leftTextField, righTextField])
        }
    }
    
}


extension ImageInfoView {
    
    private func configureExportImageBtn() {
        exportImageBtn.action = #selector(ViewController.exportImageToFormat)
    }
}
