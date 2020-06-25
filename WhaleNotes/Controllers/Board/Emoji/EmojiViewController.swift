//
//  EmojiViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class EmojiViewController:UIViewController {
    
    private var emojiCategories:[CategoryAndEmoji] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    private let itemsPerRow: CGFloat = 8
    private var sectionInsets = UIEdgeInsets(top: 0,left: 12,bottom: 0,right: 12)
    
    private let cellReuseIdentifier = "EmojiCollectionCell"
    private let headerReuseIdentifier = "EmojiSectionHeaderView"
    
    
    private lazy var searchView: EmojiSearchInputView = EmojiSearchInputView().then {
        $0.callbackTextInputChanged = {
            self.searchEmojis(keyword:$0)
        }
    }
    
    var callbackEmojiSelected:((Emoji)->Void)?
    
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.dataSource = self
        $0.delegate = self
        $0.register(EmojiCollectionCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        $0.register(EmojiSectionHeaderView.self, forSupplementaryViewOfKind:  UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "选择图标"
        self.setupUI()
        
        self.loadEmojis()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    private func setupUI() {
        self.view.backgroundColor = .white
        
        
//        let cancelButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
//        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        let barButtonItem = UIBarButtonItem(title: "随机", style: .done, target: self, action: #selector(self.doneButtonTapped))
        barButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.brand], for: .normal)
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        self.view.addSubview(collectionView)
        collectionView.backgroundColor = .white
        collectionView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        
        self.view.addSubview(searchView)
        searchView.backgroundColor = .white
        searchView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(60)
            $0.top.equalToSuperview()
        }
    }
    
    private func loadEmojis() {
        EmojiRepo.shared.loadEmojiFromCSV {
            self.emojiCategories = $0
        }
    }
    
    private func searchEmojis(keyword: String) {
        if keyword.isEmpty {
            self.loadEmojis()
            return
        }
        EmojiRepo.shared.searchEmoji(keyword: keyword) {
            if $0.isEmpty {
                self.emojiCategories = []
                return
            }
            self.emojiCategories = [
                CategoryAndEmoji(category: EmojiCategory(emoji: "", text: "", csvName: ""), emojis: $0)
            ]
        }
    }
    
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTapped() {
        EmojiRepo.shared.randomEmoji { [weak self] emoji in
            self?.setEmojiSeleced(emoji: emoji)
        }
    }
    
    
    private func setEmojiSeleced(emoji: Emoji) {
        self.callbackEmojiSelected?(emoji)
//        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
}

extension EmojiViewController: UICollectionViewDelegate,UICollectionViewDataSource {
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return emojiCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiCategories[section].emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! EmojiCollectionCell
        cell.emoji = emojiCategories[indexPath.section].emojis[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! EmojiSectionHeaderView
            sectionHeader.categoryEmoji = emojiCategories[indexPath.section]
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = self.emojiCategories[indexPath.section].emojis[indexPath.row]
        self.setEmojiSeleced(emoji: emoji)
    }
}

extension EmojiViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        var height:CGFloat = 52
        if section == 0 {
            height = 100
        }
        
        return CGSize(width: collectionView.frame.width, height: height)
    }
}
