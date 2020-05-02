//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class AttachmentsBlockCell: UITableViewCell {
    
    private static let cellCountPerRow = 2
    
    let flowLayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .vertical
    }
    
//    var imageBlock:Block! {
//        didSet {
//            self.collectionView.reloadData()
//        }
//    }
    var blocks:[Block]!
    
    static var perItemSize: CGSize {
        get {
            let width: CGFloat  = UIScreen.main.bounds.size.width - EditorViewController.space*CGFloat(cellCountPerRow) - EditorViewController.cellSpace
            let height = width*9/16
            return CGSize(width: width, height: height)
        }
    }
    
    static var itemSize: CGFloat {
        get {
            let sss: CGFloat  = UIScreen.main.bounds.size.width - EditorViewController.space*CGFloat(cellCountPerRow) - EditorViewController.cellSpace
            return  sss / CGFloat(cellCountPerRow)
        }
    }
    
    
    lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        
        guard let self = self else {return}
        
        $0.delegate = self
        $0.dataSource = self
        $0.isScrollEnabled = false
        $0.allowsSelection = false
        $0.register(ImageCell.self, forCellWithReuseIdentifier: AttachmentType.image.rawValue)
        $0.backgroundColor = .white
        
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
            make.edges.equalToSuperview()
        }
    }
    
    static func calculateCellHeight(blocks: [Block]) -> CGFloat {
//        let imagesCount = imageBlock.images.count
//        let rows = imagesCount % cellCountPerRow +  imagesCount / cellCountPerRow
//        Logger.info("哈哈哈 " ,AttachmentsBlockCell.itemSize)
//        return CGFloat(rows) * AttachmentsBlockCell.itemSize
        return 100
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

// MARK: - Collection View Flow Layout Delegate
extension AttachmentsBlockCell : UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let
//        var itemSize =  ImageBlockCell.perItemSize
//        Logger.info("cell height", itemSize)
        return AttachmentsBlockCell.perItemSize
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,left: EditorViewController.space,bottom: 0,right:  EditorViewController.space)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return EditorViewController.cellSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return EditorViewController.cellSpace
    }
    
}

