//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class ImageBlockCell: UITableViewCell {
    
    private static let cellCountPerRow = 2
    
    let flowLayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .vertical
    }
    
    var imageBlock:Block! {
        didSet {
            self.collectionView.reloadData()
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
        $0.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
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
    
    static func calculateCellHeight(imageBlock: Block) -> CGFloat {
        let imagesCount = imageBlock.images.count
        let rows = imagesCount % cellCountPerRow +  imagesCount / cellCountPerRow
        Logger.info("哈哈哈 " ,ImageBlockCell.itemSize)
        return CGFloat(rows) * ImageBlockCell.itemSize
    }
}

extension ImageBlockCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.image = imageBlock.images[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageBlock.images.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

// MARK: - Collection View Flow Layout Delegate
extension ImageBlockCell : UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemSize =  ImageBlockCell.itemSize
        Logger.info("cell height", itemSize)
        return CGSize(width: itemSize, height: itemSize)
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

