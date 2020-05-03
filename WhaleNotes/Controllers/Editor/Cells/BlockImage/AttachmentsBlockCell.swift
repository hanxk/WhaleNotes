//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import RealmSwift

enum AttachmentsConstants {
    static let cellSpace: CGFloat = 8
    static let height: CGFloat = 50
    static let radius: CGFloat = 16
}

class AttachmentsBlockCell: UITableViewCell {
    
    private var blocks:[Block] = [] {
        didSet {
            self.columnCount = blocks.count > 1 ? 2 : 1
        }
    }
    
    private var blocksSize:[CGSize] = [] {
        didSet {
            self.totalHeight =  self.calculateTotalHeight(sizes: blocksSize)
        }
    }
    
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
    private var attachmentBlocksNotifiToken: NotificationToken?
    
    
    var note:Note! {
        didSet {
            let results = note.attachBlocks.sorted(byKeyPath: "updateAt", ascending: false)
            self.attachmentBlocksNotifiToken = results.observe {[weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: let modIndices):
                    self.blocks = Array(results)
                    self.handleDataChanged(deletionIndices: deletionIndices, insertionIndices: insertionIndices, modIndices: modIndices)
                case .error(let error):
                    print(error)
                case .initial(_):
                    self.blocks = Array(results)
                    self.blocksSize =  self.caculateItemsSize(blocks:  self.blocks)
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func handleScreenRotation() {
        let count = UIDevice.current.orientation.isLandscape ? 3 : 2
        self.columnCount = blocks.count > 1 ? count : 1
        self.blocksSize = self.caculateItemsSize(blocks: self.blocks)
        
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    fileprivate func handleDataChanged(deletionIndices: [Int], insertionIndices: [Int], modIndices: [Int]) {
        
        // 刷新高度数据
        if !deletionIndices.isEmpty {
            self.blocksSize = blocksSize
                .enumerated()
                .filter { !deletionIndices.contains($0.offset) }
                .map { $0.element }
        }
        
        if !insertionIndices.isEmpty {
            
            if self.blocksSize.count == 1 { // 1个 item 的时候是 full screen, 需要重新计算所有 item
                self.blocksSize = self.caculateItemsSize(blocks: self.blocks)
            }else {
                let insertedBlocks = insertionIndices.map { index -> Block in
                    return blocks[index]
                }
                let newSizes = self.caculateItemsSize(blocks: insertedBlocks)
                // 刷新总高度
                self.blocksSize.insert(contentsOf: newSizes, at: 0)
            }
            
        }
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: deletionIndices.map({ IndexPath(row: $0, section: 0)}))
            collectionView.insertItems(at: insertionIndices.map({ IndexPath(row: $0, section: 0)}))
            collectionView.reloadItems(at: modIndices.map({ IndexPath(row: $0, section: 0)}))
        }, completion: nil)
    }
    
    
    private(set) var totalHeight:CGFloat = 0 {
        didSet {
            Logger.info("attachments height:",totalHeight)
            heightChanged?()
        }
    }
    
    func calculateTotalHeight(sizes:[CGSize]) -> CGFloat{
        var cellsHeight:[Int: CGFloat] = {
            var cellsHeight:[Int: CGFloat] = [:]
            for index in 0..<columnCount {
                cellsHeight[index] = 0
            }
            return cellsHeight
        }()
        for (_,size) in sizes.enumerated() {
            let columnIndex = getCurrentMinValueIndex(cellsHeight: cellsHeight)
            let oldHeight = cellsHeight[columnIndex] ?? 0
            let bottomSpace = ((oldHeight == 0) ? CGFloat.zero : AttachmentsConstants.cellSpace)
            Logger.info("columnIndex",columnIndex)
            Logger.info("bottomSpace",bottomSpace)
            cellsHeight[columnIndex] = oldHeight + size.height + bottomSpace
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
        $0.allowsSelection = false
        $0.register(ImageCell.self, forCellWithReuseIdentifier: AttachmentType.image.rawValue)
        $0.backgroundColor = .clear
        //        $0.backgroundColor = .blue
        
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
        let itemWidth = blocksSize[indexPath.row].width
        let itemHeight = blocksSize[indexPath.row].height
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        return columnCount
    }
    
    
}

