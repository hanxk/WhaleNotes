//
//  BoardActionView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit


enum FloatButtonConstants {
    static let btnSize:CGFloat = 56
    static let trailing:CGFloat = 16
    static let bottom:CGFloat = 26
    static let iconSize:CGFloat = 20
}

enum BoardActionViewConstants {
    static let noteBtnWidth:CGFloat = 70
    static let moreBtnWidth:CGFloat = 68
}
// 首页悬浮 view
class BoardActionView: UIView {
    
    let noteButton = UIButton().then {
        $0.contentMode = .center
        $0.backgroundColor = .clear
        $0.setImage(UIImage(systemName: "square.and.pencil", pointSize: 18), for: .normal)
    }
    
    let divider = UIView().then {
        $0.backgroundColor = UIColor.white.withAlphaComponent(0.7)
    }
    
    let moreButton = UIButton().then {
        $0.contentMode = .center
        $0.backgroundColor = .clear
        $0.setImage(UIImage(systemName: "ellipsis", pointSize: 17,weight: .light), for: .normal)
    }
    
    init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.tintColor = .white
        makeupSelf()
        
        addSubview(noteButton)
        noteButton.snp.makeConstraints {
            $0.width.equalTo(BoardActionViewConstants.noteBtnWidth)
            $0.height.equalTo(FloatButtonConstants.btnSize)
        }
        
        addSubview(divider)
        divider.snp.makeConstraints {
            $0.width.equalTo(0.5)
            $0.height.equalTo(16)
            $0.leading.equalTo(noteButton.snp.trailing)
            $0.centerY.equalToSuperview()
        }
        
        addSubview(moreButton)
        moreButton.snp.makeConstraints {
            $0.height.equalTo(FloatButtonConstants.btnSize)
            $0.width.equalTo(BoardActionViewConstants.moreBtnWidth)
            $0.leading.equalTo(divider.snp.trailing)
            $0.trailing.equalToSuperview()
        }
    }
    
    
    private func makeupSelf() {
        self.backgroundColor = UIColor(hexString: "#1F2225")
//        self.clipsToBounds = true
        let layer0 = self.layer
        layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 14
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.cornerRadius = FloatButtonConstants.btnSize / 2
        
    }
}
