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
    
    var blocks:[Block] = []
    
    var callbackCellTapped:((IndexPath) -> Void)?
    
    var columnCount = 2 {
        didSet {
            let cellCountPerRow = CGFloat(columnCount)
            let fullWidth = UIScreen.main.bounds.size.width - EditorViewController.space*2
            let width: CGFloat  = blocks.count > 1 ? (fullWidth - AttachmentsConstants.cellSpace*(cellCountPerRow-1)) / cellCountPerRow : fullWidth
            self.imageWidth = width
        }
    }
    
    
    var imageWidth: CGFloat = 0
    
    var heightChanged:(()-> Void)?
    
    let flowLayout = CHTCollectionViewWaterfallLayout().then {
        $0.minimumColumnSpacing = AttachmentsConstants.cellSpace
        $0.minimumInteritemSpacing = AttachmentsConstants.cellSpace
    }
    
    
    private func refreshHeight() {
        self.columnCount = blocks.count > 1 ? 2 : 1
        self.totalHeight =  self.calculateTotalHeight()
    }
    
    func reloadData(imageBlocks:[Block]) {
        self.blocks = imageBlocks
        self.refreshHeight()
        self.collectionView.reloadData()
    }
    
    
    func handleDataChanged(insertionIndices: [Int],insertedImages:[Block]) {
        
        self.blocks.insert(contentsOf: insertedImages, at: 0)
        self.refreshHeight()
        
        collectionView.performBatchUpdates({
            //            collectionView.deleteItems(at: deletionIndices.map({ IndexPath(row: $0, section: 0)}))
            collectionView.insertItems(at: insertionIndices.map({ IndexPath(row: $0, section: 0)}))
            //            collectionView.reloadItems(at: modIndices.map({ IndexPath(row: $0, section: 0)}))
        }, completion: nil)
    }
    
    
    private(set) var totalHeight:CGFloat = 0 {
        didSet {
            Logger.info("attachments height:",totalHeight)
            heightChanged?()
        }
    }
    
    func calculateTotalHeight() -> CGFloat{
        var cellsHeight:[Int: CGFloat] = {
            var cellsHeight:[Int: CGFloat] = [:]
            for index in 0..<columnCount {
                cellsHeight[index] = 0
            }
            return cellsHeight
        }()
        for (_,block) in blocks.enumerated() {
            
            let imageSize = self.getImageCGSize(block: block)
            
            let columnIndex = getCurrentMinValueIndex(cellsHeight: cellsHeight)
            let oldHeight = cellsHeight[columnIndex] ?? 0
            let bottomSpace = ((oldHeight == 0) ? CGFloat.zero : AttachmentsConstants.cellSpace)
            Logger.info("columnIndex",columnIndex)
            Logger.info("bottomSpace",bottomSpace)
            cellsHeight[columnIndex] = oldHeight + imageSize.height + bottomSpace
        }
        return cellsHeight.values.max() ?? 0
    }
    
    private func getCurrentMinValueIndex(cellsHeight:[Int: CGFloat] ) -> Int {
        if cellsHeight.count == 0 {
            return 0
        }
        var tempVal = CGFloat.greatestFiniteMagnitude
        var index = 0
        for (cellIndex, columnHeight) in cellsHeight {
            if tempVal > columnHeight {
                tempVal = columnHeight
                index = cellIndex
            }
        }
        return index
    }
    
    private func getImageCGSize(block:Block) -> CGSize {
        let width = block.properties["width"] as? CGFloat ?? 1000
        let height = block.properties["height"] as? CGFloat ?? 1000
        let fitHeight = self.imageWidth * height / width
        return CGSize(width: self.imageWidth, height: fitHeight)
    }
    
    private func caculateItemsSize(blocks:[Block]) -> [CGSize] {
        
        let imageWidth = self.imageWidth
        let imagesSize:[CGSize] = blocks.map {
            let url = URL(fileURLWithPath: ImageUtil.sharedInstance.dirPath.appendingPathComponent($0.source).absoluteString)
            if let data = try? Data(contentsOf: url),
                let image: UIImage = UIImage(data: data){
                let imageOriginWidth = image.size.width
                let imageOriginHeight = image.size.height
                let height = imageWidth * imageOriginHeight / imageOriginWidth
                return CGSize(width: imageWidth, height: height)
            } else {
                return CGSize(width: imageWidth, height: 0)
            }
        }
        return imagesSize
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
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCollectionView() {
        self.contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(EditorViewController.space)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
        }
        self.backgroundColor = .clear
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

