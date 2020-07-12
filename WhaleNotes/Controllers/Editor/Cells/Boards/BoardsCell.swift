//
//  BoardsCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardsCell: UITableViewCell {
    
//    var boards:[Board] = [] {
//        didSet {
//            collectionView.reloadData()
//        }
//    }
    
    static let cellHeight:CGFloat = BoardTagCell.cellHeight + 10
    private let cellReuseIndetifier = "BoardTagCell"
    private var cachedWidth:[String:CGFloat] = [:]
    
    var callbackTaped:(()->Void)?
    
    let flowLayout = LeftAlignedCollectionViewFlowLayout().then {
        $0.minimumLineSpacing = 6
        $0.minimumInteritemSpacing = 7
        $0.scrollDirection = .horizontal
//        $0.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
//        $0.itemSize = CGSize(width: 100, height: BoardTagCell.cellHeight)
    }
    
    lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        guard let self = self else {return}
//        $0.delegate = self
//        $0.dataSource = self
//        $0.allowsSelection = true
//        $0.showsHorizontalScrollIndicator = false
//        $0.register(BoardTagCell.self, forCellWithReuseIdentifier: self.cellReuseIndetifier)
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
            make.height.equalToSuperview()
            make.width.equalToSuperview()
        }
        self.backgroundColor = .clear
    }
}

//extension BoardsCell: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:cellReuseIndetifier, for: indexPath) as! BoardTagCell
//        cell.board = self.boards[indexPath.row]
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return boards.count
//    }
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//
//}


//extension BoardsCell: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        let board = self.boards[indexPath.row]
//        let text = board.icon + board.title
//        if let width = cachedWidth[text] {
//            return CGSize(width: width, height: BoardTagCell.cellHeight)
//        }
//        var width  = BoardTagCell.cellWidth(board: self.boards[indexPath.row])
//        if width > 200 {
//            width = 200
//        }
//         cachedWidth[text] = width
//        return CGSize(width: width, height: BoardTagCell.cellHeight)
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: EditorViewController.space, bottom: 0, right: EditorViewController.space)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        callbackTaped?()
//    }
//}
