//
//  ImageView.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit


class ImageView: NSView {
    @IBOutlet weak var chooseImageBtn: RoundedButton!
    @IBOutlet weak var delegate: ImageViewDelegate?
    @IBOutlet weak var imageView: NSImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.unregisterDraggedTypes()
        configureChooseImageBtn()
        configureImageView()
    }

    func configureImageView() {
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.borderWidth = 2.0
        imageView.layer?.borderColor = NSColor(calibratedWhite: 0.5, alpha: 0.5).cgColor
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return delegate?.draggingEntered(forImageView: self, sender: sender) ?? []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.performDragOperation(forImageView: self, sender: sender) ?? false
    }
    
    private func configureChooseImageBtn() {
        chooseImageBtn.action = #selector(ViewController.chooseImage)
    }
    
}


@objc protocol ImageViewDelegate: AnyObject {
    func draggingEntered(forImageView imageView: ImageView, sender: NSDraggingInfo) -> NSDragOperation
    func performDragOperation(forImageView imageView: ImageView, sender: NSDraggingInfo) -> Bool
}
