//
//  TODOAddNewCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/22.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

class TODOAddNewCell: UITableViewCell {
    
    private let addNewImage: UIImageView = UIImageView().then {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        $0.image = UIImage(systemName: "plus", withConfiguration: config)
        $0.tintColor = .thirdColor
        
        $0.contentMode = .center
    }
    
    private let addButton: UIButton = UIButton().then {
        $0.setTitle("添加清单项", for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    
    private let menuButton: UIButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        $0.tintColor  = .thirdColor
    }
    
    private let label: UILabel = UILabel().then {
        $0.text = "添加清单项"
        $0.textAlignment = .left
        $0.backgroundColor = UIColor.clear
        $0.textColor = .brand
        $0.font = UIFont.systemFont(ofSize: 14)
    }
    
    var textChanged: ((UITextView) -> Void)?
    var textShouldBeginChange: ((UITextView) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.selectionStyle = .none
        contentView.addSubview(addButton)
        contentView.addSubview(menuButton)
        
        self.setupConstraints()
    }
    
    private func setupConstraints() {
        
        let topSpace = 2
        
        addButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topSpace)
            make.bottom.equalToSuperview().offset(-topSpace)
            make.leading.equalToSuperview().offset(NoteEditorViewController.space)
        }
        menuButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topSpace)
            make.bottom.equalToSuperview().offset(-topSpace)
            make.trailing.equalToSuperview().offset(-NoteEditorViewController.space)
        }
    }
    
    private func handleAddButtonTapped() {
        
    }
    
}
