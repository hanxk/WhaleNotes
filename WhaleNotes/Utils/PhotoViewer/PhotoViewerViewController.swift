//
//  PhotoViewerViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import JXPhotoBrowser
import RxSwift


class PhotoViewerViewController:JXPhotoBrowser {
    
    private var isBlockDeleted = false
    var isFromNoteDetail:Bool = false
    
    private var note:Note!
    private var imageBlocks:[Block] {
        return note.attachmentBlocks
    }
    
    var callBackShowNoteButtonTapped:(()->Void)?
    var callbackPhotoBlockDeleted:((Note)->Void)?
    
    private let horizontalPadding:CGFloat = 8
    private let topHeight:CGFloat = 36
    private let pageHeight:CGFloat  = 24
    private let iconButtonSize:CGFloat = 36
    
    private let buttonColor = UIColor.black.withAlphaComponent(0.6)
    
    private lazy var disposeBag = DisposeBag()
    
    private lazy var  noteButton:UIButton = UIButton().then {
        $0.setTitle("查看笔记", for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.layer.cornerRadius = iconButtonSize / 2
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        $0.addTarget(self, action: #selector(self.showNoteButtonTapped), for: .touchUpInside)
    }
    
    private lazy var titleLabel:UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 18,weight: .regular)
        $0.textColor = UIColor.white
        $0.textDropShadow()
    }
    
    private lazy var closeButton:UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "multiply", pointSize: 20, weight: .light), for: .normal)
        $0.tintColor = .white
        $0.layer.cornerRadius = iconButtonSize / 2
        $0.addTarget(self, action: #selector(self.closeVC), for: .touchUpInside)
    }
    
    
    private lazy var deleteButton:UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "trash", pointSize: 17, weight: .light), for: .normal)
        $0.tintColor = .white
        $0.layer.cornerRadius = iconButtonSize / 2
        $0.addTarget(self, action: #selector(self.deleteImage), for: .touchUpInside)
    }
    
    private lazy var topPadding: CGFloat = {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return keyWindow?.safeAreaInsets.top ?? 20
    }()
    
    public typealias PhotoViewerTranAnimProvider = (_ index: Int, _ destinationView: UIView) -> (transitionView: UIView, thumbnailFrame: CGRect)
    
    convenience init(note:Note,pageIndex:Int = 0) {
        self.init()
        self.note = note
        self.pageIndex = pageIndex
        self.browserView.numberOfItems = {
            self.imageBlocks.count
        }
        
        self.reloadCellAtIndex = { context in
            if let browserCell = context.cell as? JXPhotoBrowserImageCell {
                let fileURL = ImageUtil.sharedInstance.filePath(imageName: self.imageBlocks[context.index].blockImageProperties!.url)
                browserCell.imageView.setLocalImage(fileURL: fileURL) {
                    browserCell.setNeedsLayout()
                }
            }
        }
        self.didChangedPageIndex = { pageIndex in
            self.refreshPageIndex()
        }
        self.refreshPageIndex()
    }
    private func refreshPageIndex() {
        self.titleLabel.set(text: "\(pageIndex+1)/\(self.note.attachmentBlocks.count)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        closeButton.backgroundColor = buttonColor
        deleteButton.backgroundColor = buttonColor
        noteButton.backgroundColor = buttonColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        closeButton.backgroundColor = .clear
        deleteButton.backgroundColor = .clear
        
        if isBlockDeleted {
            callbackPhotoBlockDeleted?(self.note)
        }
    }
    
    private func setupUI() {
        
        
        self.view.addSubview(closeButton)
        self.closeButton.snp.makeConstraints {
            $0.width.height.equalTo(iconButtonSize)
            $0.top.equalToSuperview().offset(topPadding)
            $0.left.equalToSuperview().offset(horizontalPadding)
        }
        
        if !isFromNoteDetail {
            self.view.addSubview(noteButton)
            self.noteButton.snp.makeConstraints {
                $0.top.equalToSuperview().offset(topPadding)
                $0.right.equalToSuperview().offset(-horizontalPadding)
                $0.height.equalTo(topHeight)
                
            }
        }
        
        self.view.addSubview(titleLabel)
        self.titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(closeButton)
            $0.height.equalTo(pageHeight)
        }
        
        
        self.view.addSubview(deleteButton)
        self.deleteButton.snp.makeConstraints {
            $0.width.height.equalTo(iconButtonSize)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-horizontalPadding)
            $0.right.equalToSuperview().offset(-horizontalPadding)
        }
        
    }
    
    @objc private func closeVC() {
        self.dismiss()
    }
    
    @objc private func showNoteButtonTapped() {
        self.dismiss()
        callBackShowNoteButtonTapped?()
    }
    
    @objc private func deleteImage() {
        let alert = UIAlertController(title: "删除图片", message: "你确定要彻底删除该图片吗？", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
        self.handleImageDeleted()
      }))
      alert.addAction(UIAlertAction(title: "取消", style: .cancel,handler: nil))
      self.present(alert, animated: true)
    }
    
    private func handleImageDeleted() {
        let block = self.imageBlocks[self.pageIndex]
        NoteRepo.shared.deleteBlock(block: block)
            .subscribe(onNext: { isSuccess in
                self.note.removeBlock(block: block)
                self.isBlockDeleted = true
                if self.imageBlocks.isEmpty {
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                self.browserView.reloadData()
                self.refreshPageIndex()
                
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    
}

struct UIImageArgu {
    let image:UIImage
    let view:UIView
}
