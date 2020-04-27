//
//  TodoCompleteHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import UIKit

class TodoCompleteHeaderView: UIView {
    
    private lazy var addButton: UIButton = UIButton().then {
        $0.setTitle("展开清单项目", for: .normal)
        $0.setTitleColor(.thirdColor, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
//    private let menuButton: UIButton = UIButton().then {
//        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
//        $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
//        $0.tintColor  = .thirdColor
//    }
    
    var todoBlock: Block!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    private func setup() {
        let topSpace = 2
        
        self.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topSpace)
            make.bottom.equalToSuperview().offset(-topSpace)
            make.leading.equalToSuperview().offset(EditorViewController.space)
        }
        
//        self.addSubview(menuButton)
//        menuButton.snp.makeConstraints { (make) in
//            make.top.equalToSuperview().offset(topSpace)
//            make.bottom.equalToSuperview().offset(-topSpace)
//            make.trailing.equalToSuperview().offset(-EditorViewController.space)
//        }
    }
    
    @objc private func handleAddButtonTapped() {
        DBManager.sharedInstance.update { [weak self] in
            if let self = self {
                self.todoBlock.todos.insert(Todo(text: "", block: self.todoBlock),at: 0)
            }
        }
    }
}
