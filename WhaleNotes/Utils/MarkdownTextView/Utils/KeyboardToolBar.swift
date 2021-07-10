//
//  KeyboardInputBar.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit


protocol KeyboardToolBarDelegate: AnyObject {
    func headerButtonTapped()
    func boldButtonTapped()
    func tagButtonTapped()
    func listButtonTapped()
    func orderListButtonTapped()
    func pickPhotoButtonTapped(sourceType:UIImagePickerController.SourceType)
    func keyboardButtonTapped()
}
class KeyboardToolBar:NSObject {
    
    let toolbar = UIToolbar().then {
        $0.tintColor = UIColor(hexString: "#414141")
        $0.clipsToBounds =  true
    }
    private var items:[(String,Selector?)] = [
        ("camera",nil),
        ("grid",#selector(tagButtonTapped)),
        ("bold",#selector(boldButtonTapped)),
        ("list.bullet",#selector(bulletListButtonTapped)),
        ("list.number",#selector(numberListButtonTapped))
    ]
    
    var toolbarItems:[UIBarButtonItem] = []
    var delegate:KeyboardToolBarDelegate?
    weak var vc:UIViewController? = nil
    
    override init() {
        super.init()
        self.setup()
    }
    
    private func setup() {
        for item in items {
            
            let toolbarItem = UIBarButtonItem(image: UIImage(systemName: item.0), style: .plain, target: self, action: item.1)
            if item.0 == "camera" {
                let items = UIMenu(title: "", options: .displayInline, children: [
                    UIAction(title: "拍照或录视频", image: UIImage(systemName: "camera"), handler: { _ in
//                        self.handlePickPhotos(sourceType: .camera)
                        self.cameraButtonTapped(sourceType: .camera)
                    }),
                    UIAction(title: "选取照片或视频", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in
//                        self.handlePickPhotos(sourceType: .photoLibrary)
                        self.cameraButtonTapped(sourceType: .photoLibrary)
                    }),
                ])
                toolbarItem.menu =  UIMenu(title: "", children: [items])
            }
            toolbarItems.append(toolbarItem)
            let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            space.width = 10
            toolbarItems.append(space)
        }
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems.append(spacer)
        
        let doneItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(keyboardButtonTapped))
        doneItem.tintColor = .brand
        toolbarItems.append(doneItem)
        
        toolbar.items = toolbarItems
        toolbar.sizeToFit()
    }
}

extension KeyboardToolBar {
    
    
    fileprivate func cameraButtonTapped(sourceType:UIImagePickerController.SourceType) {
        delegate?.pickPhotoButtonTapped(sourceType: sourceType)
    }
    @objc fileprivate func headerButtonTapped() {
        delegate?.headerButtonTapped()
    }
    @objc fileprivate func boldButtonTapped() {
        delegate?.boldButtonTapped()
    }
    @objc fileprivate func tagButtonTapped() {
        delegate?.tagButtonTapped()
    }
    @objc fileprivate func bulletListButtonTapped() {
        delegate?.listButtonTapped()
    }
    @objc fileprivate func numberListButtonTapped() {
        delegate?.orderListButtonTapped()
    }
    @objc fileprivate func keyboardButtonTapped() {
        delegate?.keyboardButtonTapped()
    }
}
