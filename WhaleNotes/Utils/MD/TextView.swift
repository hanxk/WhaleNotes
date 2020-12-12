//
//  TextView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/11.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import Alamofire
import MobileCoreServices

class TextView: UITextView, UIDropInteractionDelegate {
    
//    weak var file: File? {
//        didSet {
//            let folderName = file?.displayName ?? ""
//            imageFolder = file?.parent?.children.first { $0.name == folderName }
//        }
//    }
    weak var viewController: UIViewController? =   nil
    
    
    convenience init() {
        self.init(frame: .zero)
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }
    
    
//    var imageFolder: File?
    
    var shouldResign = false
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        if !isFirstResponder {
            shouldResign = true
            becomeFirstResponder()
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        if shouldResign {
            resignFirstResponder()
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeImage as String, kUTTypeText as String, kUTTypeURL as String]) && session.items.count == 1
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let point = session.location(in: self)
        if let position = closestPosition(to: point) {
            let location = offset(from: beginningOfDocument, to: position)
            selectedRange = NSRange(location: location, length: 0)
        }
        let dropProposal = UIDropProposal(operation: .copy)
        dropProposal.isPrecise = true
        return dropProposal
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        if session.canLoadObjects(ofClass: UIImage.self) {
            _ = session.loadObjects(ofClass: UIImage.self) { (items) in
                if items.count > 0 {
                    self.insertImage(items.first as! UIImage)
                }
            }
        } else if session.canLoadObjects(ofClass: URL.self) {
            _ = session.loadObjects(ofClass: URL.self) { (items) in
                if items.count > 0 {
                    self.insertURL((items.first!).absoluteString)
                }
            }
        } else {
            _ = session.loadObjects(ofClass: String.self) { (items) in
                if items.count > 0 {
                    self.insertText(items.first!)
                }
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return true
        }

        return super.canPerformAction(action, withSender: sender)
    }
    
    override func paste(_ sender: Any?) {
        for item in UIPasteboard.general.items {

            if let image = item["public.jpeg"] as? UIImage {
                insertImage(image)
                return
            }

            if let image = item["public.png"] as? UIImage {
                insertImage(image)
                return
            }
        }

        super.paste(sender)
    }
    
    func insertURL(_ link: String) {
        let currentRange = self.selectedRange
        let text = "EnterLink"
        insertText("[\(text)](\(link))")
        selectedRange = NSRange(location:currentRange.location + 1, length: text.length)
    }
    
    func insertImage(_ image: UIImage) {
//        guard (self.file?.parent) != nil else {
//            self.uploadImage(image)
//            return
//        }
//        if Configure.shared.imageStorage == .local {
//            copyImageToLocal(image)
//        } else if Configure.shared.imageStorage == .remote {
//            uploadImage(image)
//        } else {
//            resignFirstResponder()
//            viewController?.showActionSheet(title: "ImageUploadTips", actionTitles: ["ImageStorageRemote","ImageStorageLocal"]) { (index) in
//                if index == 0 {
//                    self.uploadImage(image)
//                } else if index == 1 {
//                    self.copyImageToLocal(image)
//                }
//                if !Configure.shared.showedTips.contains("3") {
//                    Configure.shared.showedTips.append("3")
//                    DispatchQueue.main.async {
//                        self.viewController?.showAlert(title: "Tips", message: "ImageStorageTips", actionTitles: ["GotIt"])
//                    }
//                }
//            }
//        }
    }
    
    func insertImagePath(_ path: String) {
        self.becomeFirstResponder()
        let currentRange = self.selectedRange
        let text = "Alt"
        self.insertText("![\(text)](\(path))")
        self.selectedRange = NSRange(location: currentRange.location + 2, length: text.length)
    }
    
//    func copyImageToLocal(_ image: UIImage) {
//        let pixelCount = image.size.width * image.size.height
//        let scale = max(min(1024 * 1024 / pixelCount,1.0),0.8)
//        guard let data = image.data(scale) else { return }
//        let md5 = data.md5()
//
//        let cachePath = Configure.shared.imageCaches[md5] ?? ""
//        if self.imageFolder != nil &&
//            cachePath.hasPrefix(self.imageFolder!.displayName) &&
//            FileManager.default.fileExists(atPath: self.imageFolder!.path.stringByDeleteLastPath().stringByAppendingPath(cachePath)) {
//            self.insertImagePath(cachePath)
//            return
//        }
//        guard let parent = self.file?.parent else { return }
//
//        let folderName = self.file?.displayName ?? ""
//        if imageFolder == nil {
//            imageFolder = parent.createFile(name: folderName, contents: nil, type: .folder)
//        }
//        let index = imageFolder?.children.filter({$0.displayName.hasPrefix("img-ref-")}).sorted{$0.name.localizedCompare($1.name) == .orderedAscending}.last?.displayName.components(separatedBy: "-").last?.toInt() ?? -1
//        let name = "img-ref-\(index+1)"
//
//        guard let imageFolder = self.imageFolder, let imageFile = imageFolder.createFile(name: name, contents: data, type: .image) else {
//            return
//        }
//        let path = "\(imageFolder.name)/\(imageFile.name)"
//        insertImagePath(path)
//        Configure.shared.imageCaches[md5] = path
//    }
    
//    func uploadImage(_ image: UIImage) {
//        let pixelCount = image.size.width * image.size.height
//        let scale = max(min(1024 * 1024 / pixelCount,1.0),0.6)
//
//        guard let data = image.data(scale) else { return }
//        let md5 = data.md5()
//        let cachePath = Configure.shared.imageCaches[md5] ?? ""
//        if cachePath.hasPrefix("http") {
//            self.insertImagePath(cachePath)
//            return
//        }
//
//        ActivityIndicator.show()
//        Alamofire.upload(multipartFormData: { (formData) in
//            formData.append(data, withName: "smfile", fileName: "temp", mimeType: "image/jpg")
//        }, to: imageUploadUrl,headers:["Authorization":smKey]) { [weak self] (result) in
//            switch result {
//            case .success(let upload,_, _):
//                upload.responseJSON{ (response) in
//                    if case .success(let json) = response.result {
//                        ActivityIndicator.dismiss()
//                        let dict = json as? [String:Any] ?? [:]
//                        var url: String? = nil
//                        if let data = dict["data"] as? [String:Any] {
//                            url = data["url"] as? String
//                        }
//                        if url == nil {
//                            if let message = dict["message"] as? String {
//                                url = message.firstMatch("https.*jpg")
//                            }
//                        }
//                        if let url = url {
//                            Configure.shared.imageCaches[md5] = url
//                            self?.insertImagePath(url)
//                        } else if let message = dict["message"] as? String {
//                            ActivityIndicator.showError(withStatus: message)
//                        }
//                    } else if case .failure(let error) = response.result {
//                        ActivityIndicator.dismiss()
//                        ActivityIndicator.showError(withStatus: error.localizedDescription)
//                    }
//                }
//            case .failure(let error):
//                ActivityIndicator.dismiss()
//                ActivityIndicator.showError(withStatus: error.localizedDescription)
//            }
//        }
//    }
}
