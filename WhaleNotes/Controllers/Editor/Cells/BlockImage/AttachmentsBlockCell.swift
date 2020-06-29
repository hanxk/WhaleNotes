//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import JXPhotoBrowser

enum AttachmentsConstants {
    static let cellSpace: CGFloat = 8
    static let height: CGFloat = 50
    static let radius: CGFloat = 6
}

class AttachmentsBlockCell: UITableViewCell {
    
    var blocks:[Block] = [] {
        didSet {
            self.columnCount = self.blocks.count > 1 ? 2 : 1
        }
    }
    var callbackCellTapped:((IndexPath) -> Void)?
    
    var imageWidth: CGFloat = 0
    private var columnCount = 2
    
    var heightChanged:(()-> Void)?
    
    let flowLayout = CHTCollectionViewWaterfallLayout().then {
        $0.minimumColumnSpacing = AttachmentsConstants.cellSpace
        $0.minimumInteritemSpacing = AttachmentsConstants.cellSpace
    }
    
    private(set) var totalHeight:CGFloat = 0 {
        didSet {
            Logger.info("attachments height:",totalHeight)
            heightChanged?()
        }
    }
    
    lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        guard let self = self else {return}
        $0.delegate = self
        $0.dataSource = self
        $0.isScrollEnabled = false
        $0.allowsSelection = true
        $0.register(ImageCell.self, forCellWithReuseIdentifier: AttachmentType.image.rawValue)
        $0.backgroundColor = .clear
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(EditorViewController.space)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
        }
        self.backgroundColor = .clear
    }
    
    func handleDataChanged(insertionIndices: [Int],insertedImages:[Block]) {
        self.blocks.insert(contentsOf: insertedImages, at: 0)
        collectionView.performBatchUpdates({
            //            collectionView.deleteItems(at: deletionIndices.map({ IndexPath(row: $0, section: 0)}))
            collectionView.insertItems(at: insertionIndices.map({ IndexPath(row: $0, section: 0)}))
            //            collectionView.reloadItems(at: modIndices.map({ IndexPath(row: $0, section: 0)}))
        }, completion: nil)
    }
}

extension AttachmentsBlockCell {
    
    func reloadData(imageBlocks:[Block]) {
        self.blocks = imageBlocks
        self.collectionView.reloadData()
    }
    
    private func getImageCGSize(block:Block) -> CGSize {
        let width = block.properties["width"] as? CGFloat ?? 1000
        let height = block.properties["height"] as? CGFloat ?? 1000
        let fitHeight = self.imageWidth * height / width
        return CGSize(width: self.imageWidth, height: fitHeight)
    }
    
}

extension AttachmentsBlockCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentType.image.rawValue, for: indexPath) as! ImageCell
        cell.imageBlock = self.blocks[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blocks.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

enum AttachmentType:String {
    case image = "image"
}


extension AttachmentsBlockCell: CHTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.getImageCGSize(block: self.blocks[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        return columnCount
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        callbackCellTapped?(indexPath)
    }
    
}

