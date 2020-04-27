//
//  TodoHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoHeaderView: UIView {
    
    private lazy var addButton: UIButton = UIButton().then {
        $0.setTitle("添加清单项", for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
    private let menuButton: UIButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        $0.tintColor  = .thirdColor
    }
    
    var todoBlock: Block!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
        self.backgroundColor = .white
    }
    
    private func setup() {
        self.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(EditorViewController.space)
        }
        
        self.addSubview(menuButton)
        menuButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
        }
    }
    
    @objc private func handleAddButtonTapped() {
        DBManager.sharedInstance.update { [weak self] in
            if let self = self {
                self.todoBlock.todos.insert(Todo(text: "", block: self.todoBlock),at: 0)
            }
        }
    }
}
