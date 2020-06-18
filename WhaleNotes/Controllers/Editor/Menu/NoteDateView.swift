//
//  NoteDateView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


class NoteDateView: UIView {
    
    static let contentHeight:CGFloat = 120
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        let updateTitleLabel = generateTitleView(text: "更新时间")
        let updateValueLabel = generateValueView(text: "2018年12月10日 10:30")
        
        let spacing = 8
        
        self.addSubview(updateTitleLabel)
        updateTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(NoteDetailMenuCell.padding)
            $0.top.equalToSuperview().offset(10)
        }
        
        self.addSubview(updateValueLabel)
        updateValueLabel.snp.makeConstraints {
            $0.leading.equalTo(updateTitleLabel.snp.leading)
            $0.top.equalTo(updateTitleLabel.snp.bottom).offset(spacing)
        }
        
        
        let createdTitleLabel = generateTitleView(text: "创建时间")
        let createdValueLabel = generateValueView(text: "2018年12月10日 10:30")
        self.addSubview(createdTitleLabel)
       createdTitleLabel.snp.makeConstraints {
           $0.leading.equalToSuperview().offset(NoteDetailMenuCell.padding)
        $0.top.equalTo(updateValueLabel.snp.bottom).offset(14)
       }
       
       self.addSubview(createdValueLabel)
       createdValueLabel.snp.makeConstraints {
           $0.leading.equalTo(updateTitleLabel.snp.leading)
           $0.top.equalTo(createdTitleLabel.snp.bottom).offset(spacing)
       }
    }
    
    private func generateTitleView(text:String) -> UILabel {
        let label = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 12)
            $0.textColor = UIColor.init(hexString: "#666666")
            $0.text = text
        }
        return label
    }
    
    private func generateValueView(text:String) -> UILabel {
        let label = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 13)
            $0.textColor = UIColor.init(hexString: "#333333")
            $0.text = text
        }
        return label
    }
}
