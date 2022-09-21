//
//  ViewController.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Cocoa
import UniformTypeIdentifiers

class ViewController: NSViewController, ImageViewDelegate {
    
    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageInfoView: ImageInfoView!
    
    var qoiData: Data?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map({ type in
            NSPasteboard.PasteboardType(type)
        }))
        imageView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    private lazy var operationQueue : OperationQueue = {
        let workingQueue = OperationQueue()
        workingQueue.qualityOfService = .userInitiated
        return workingQueue
    }()
    
    private lazy var destinationURL : URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("QFormatImageFolder")
        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError("\(error.localizedDescription)")
        }
        return destinationURL
    }()
    
    func draggingEntered(forImageView imageView: ImageView, sender: NSDraggingInfo) -> NSDragOperation {
        var isValid = false
        enumerate(draggingInfo: sender) { draggingItem, index, stop in
            isValid = true
            stop.pointee = true
        }
        return isValid ? sender.draggingSourceOperationMask.intersection([.copy]) : []
    }
    
    func performDragOperation(forImageView imageView: ImageView, sender: NSDraggingInfo) -> Bool {
        enumerate(draggingInfo: sender) { draggingItem, _, _ in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, operationQueue: self.operationQueue) { url, error in
                    if let error = error {
                        print("We have an error: \(error)")
                    } else {
                        self.handleFile(at: url)
                    }
                }
            case let fileURL as URL:
                self.handleFile(at: fileURL)
            default:
                break
            }
        }
        return true
    }
}

extension ViewController {
    
    private func handleFile(at url: URL) {
        let image = NSImage(image: url)
        
        if let image = image {
            
            if imageView.imageView.image == nil {
                self.view.removeConstraint(imageViewTrailingConstraint)
                self.imageView.trailingAnchor.constraint(equalTo: self.imageInfoView.leadingAnchor).isActive = true
            }
            
            self.imageView.imageView.image = image
            self.imageView.imageView.layer?.borderWidth = 0.0
            self.imageInfoView.handleImageInfo(image, file: url)
            self.imageInfoView.isHidden = false
            self.imageInfoView.exportImageBtn.needsDisplay = true
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.allowsImplicitAnimation = true
                self.view.layoutSubtreeIfNeeded()
            }
            
            DispatchQueue.global(qos: .utility).async {
                guard let (bytes, width, height, channels) = image.asData() else { return }
                let header = QOICoder.QOIHeader(width: UInt32(width), height: UInt32(height), channels: UInt8(channels) , colorspace: .Linear)
                guard let encoded = QOICoder.encode(bytes, header) else { return }
                self.qoiData = encoded
            }
            
        }
    }
    
}

extension ViewController {
    
    private func enumerate(draggingInfo: NSDraggingInfo, using block: @escaping (NSDraggingItem, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]
        
        let searchOptions: [NSPasteboard.ReadingOptionKey : Any] = [
            .urlReadingFileURLsOnly : true,
            .urlReadingContentsConformToTypes : [UTType.image.identifier, UTType("com.QFormat.qoi")!.identifier]
        ]
        
        draggingInfo.enumerateDraggingItems(for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, index, stop in
            block(draggingItem, index, stop)
        }
    }
}


extension ViewController {
    @objc func chooseImage() {
        let dialog = NSOpenPanel()
        
        dialog.title = "Choose an Image | QFormat"
        dialog.prompt = "Choose"
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = true
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedContentTypes = [.image, UTType("com.QFormat.qoi")!]
        
        
        dialog.beginSheetModal(for: self.view.window!) { response in
            guard response == .OK else { return }
            
            guard let url = dialog.url else { return }
            
            self.handleFile(at: url)
        }
    }
    
    @objc func exportImageToFormat() {
        guard let image = self.imageView.imageView.image else { return }
        
        guard let selectedItem = self.imageInfoView.chooseExportFormatBtn.selectedItem, selectedItem.isEnabled else {
            return
        }
        
        var data: Data?
        var fileExtension: UTType?
        switch (selectedItem.title) {
        case "QOI":
            var qoiEncodedImage: Data?
            if let preEncoded = self.qoiData {
                qoiEncodedImage = preEncoded
            } else {
                guard let (bytes, width, height, channels) = image.asData() else { return }
                let header = QOICoder.QOIHeader(width: UInt32(width), height: UInt32(height), channels: UInt8(channels), colorspace: .Linear)
                guard let encoded = QOICoder.encode(bytes, header) else { return }
                qoiEncodedImage = encoded
            }
            data = qoiEncodedImage
            fileExtension = UTType("com.QFormat.qoi")
        case "PNG":
            data = image.pngData()
            fileExtension = UTType.png
        case "JPEG":
            data = image.jpegData()
            fileExtension = UTType.jpeg
        case "TIFF":
            data = image.tiffRepresentation
            fileExtension = UTType.tiff
        default:
            break
        }
        
        guard let data = data, let fileExtension = fileExtension else { return }
        
        let dialog = NSSavePanel()
        
        dialog.title = "Save the Image | QFormat"
        dialog.showsResizeIndicator = false
        dialog.showsHiddenFiles = false
        dialog.allowsOtherFileTypes = false
        dialog.canCreateDirectories = true
        dialog.isExtensionHidden = false
        dialog.canSelectHiddenExtension = false
        dialog.prompt = "Export"
        dialog.allowedContentTypes = [fileExtension]
        
        
        dialog.beginSheetModal(for: self.view.window!) { response in
            guard response == .OK else { return }
            
            guard let url = dialog.url else { return }
            
            do {
                try data.write(to: url)
            } catch let error {
                print("\(error.localizedDescription)")
            }
        }
    }
}
