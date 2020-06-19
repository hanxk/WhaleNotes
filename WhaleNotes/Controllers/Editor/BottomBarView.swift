//
//  BottomBarView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/21.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

class BottomBarView: UIView {
    
    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
    lazy var addButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus.circle",withConfiguration: config), for: .normal)
    }
    
    lazy var moreButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName:  "ellipsis", pointSize: 20, weight: .regular), for: .normal)
    }
    
    lazy var keyboardButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName:  "keyboard.chevron.compact.down", pointSize: 18, weight: .regular), for: .normal)
        $0.isHidden = true
    }
    
    lazy var updatedAtText: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 13)
        $0.textColor = UIColor(hexString: "#666666")
    }
    
    var updatedDateStr:String = "" {
        didSet {
            self.updatedAtText.text = updatedDateStr
        }
    }
    
    var isKeyboardShow:Bool = false {
        didSet {
            self.moreButton.isHidden = isKeyboardShow
            self.keyboardButton.isHidden = !isKeyboardShow
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.leading.equalToSuperview().offset(3)
            make.centerY.equalToSuperview()
        }
        
        addSubview(moreButton)
        moreButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.trailing.equalToSuperview().offset(-5)
            make.top.bottom.equalToSuperview()
        }
        
        addSubview(keyboardButton)
        keyboardButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.trailing.equalToSuperview().offset(-5)
            make.top.bottom.equalToSuperview()
        }
        
        addSubview(updatedAtText)
        updatedAtText.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        tintColor = .buttonTintColor

    }
}
