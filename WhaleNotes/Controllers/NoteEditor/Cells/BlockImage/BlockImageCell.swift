//
//  BlockImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BlockImagecCollectionCell: UITableViewCell {
    
     let flowLayout = UICollectionViewFlowLayout().then {
          $0.scrollDirection = .vertical
//          $0.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
      }
    
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
         
         $0.register(TitleTableViewCell.self, forCellWithReuseIdentifier:  CellType.title.rawValue)
         
     }
     
}
