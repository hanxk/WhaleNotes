//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BlockImageCell: UITableViewCell {
    
     let flowLayout = UICollectionViewFlowLayout().then {
          $0.scrollDirection = .vertical
//          $0.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
      }

    let itemSize = (UIScreen.main.bounds.size.width - EditorViewController.space*2 - EditorViewController.cellSpace)/2
    
     lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
         
         guard let self = self else {return}
         
         $0.delegate = self
         $0.dataSource = self
         $0.isScrollEnabled = true
         $0.alwaysBounceVertical = true
         
         $0.showsVerticalScrollIndicator = true
         $0.showsHorizontalScrollIndicator  = false
         $0.backgroundColor = UIColor.white
         $0.allowsSelection = true
         //        $0.backgroundColor   = .blue
         
         $0.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
         
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
            
            make.top.equalToSuperview()
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
//            make.edges.equalToSuperview()
            make.height.equalTo(self.itemSize)
        }
    }
    
     
}

extension BlockImageCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    
}

// MARK: - Collection View Flow Layout Delegate
extension BlockImageCell : UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: itemSize, height: itemSize)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets.init()
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return EditorViewController.cellSpace
    }
    
}

