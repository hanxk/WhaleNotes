//
//  NoteColorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class NoteColorViewController: UIViewController {
    
    var colors:[String] = ["#FFFFFF","#FBCFCE",
                           "#FDDFCC","#FCE9AD",
                           "#F0FDB7","#CAFCEE",
                           "#C5EBFD","#CADDFD"]
    
    private let cellReuseIndetifier = "NoteColorCell"
    private var cachedWidth:[String:CGFloat] = [:]
    
    var callbackColorChoosed:((String)->Void)?
    
    let flowLayout = UICollectionViewFlowLayout().then {
        $0.minimumLineSpacing = 20
        $0.minimumInteritemSpacing = 0
        $0.scrollDirection = .vertical
        $0.itemSize = CGSize(width: NoteColorCell.cellHeight, height: NoteColorCell.cellHeight)
        
        let horizontalPadding = (NoteMenuViewController.menuWidth - $0.minimumLineSpacing - NoteColorCell.cellHeight * 3) / 2
        let topPadding:CGFloat = 10
        
        $0.sectionInset = UIEdgeInsets(top: topPadding, left: horizontalPadding, bottom: topPadding, right: horizontalPadding)
    }
    
    lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        guard let self = self else {return}
        $0.delegate = self
        $0.dataSource = self
        $0.allowsSelection = true
        $0.register(NoteColorCell.self, forCellWithReuseIdentifier: self.cellReuseIndetifier)
        $0.backgroundColor = .white
        $0.alwaysBounceVertical = true
    }
    
    private func setupCollectionView() {
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "背景色"
        setupCollectionView()
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
}

extension NoteColorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:cellReuseIndetifier, for: indexPath) as! NoteColorCell
        cell.color = self.colors[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
}


extension NoteColorViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        callbackColorChoosed?(self.colors[indexPath.row])
    }
}
