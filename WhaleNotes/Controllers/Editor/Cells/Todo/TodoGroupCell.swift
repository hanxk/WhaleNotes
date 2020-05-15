//
//  TodoGroupCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/15.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoGroupCell: UITableViewCell {
    
    var arrowButtonTapped:((Block) ->Void)?
    var menuButtonTapped:((UIButton,Block) ->Void)?
    
    private lazy var arrowDownImage:UIImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .light)
        var image = UIImage(systemName: "chevron.down", withConfiguration: config)
        return image!
    }()
    
    private lazy var arrowRightImage:UIImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .light)
        var image = UIImage(systemName: "chevron.right", withConfiguration: config)
        return image!
    }()
    
    private lazy var arrowButton: UIButton = UIButton().then {
        $0.contentMode = .center
        $0.imageView?.tintColor  = UIColor(hexString: "#616264")
        $0.imageView?.contentMode = .scaleAspectFit
        $0.addTarget(self, action: #selector(self.handleArrowButtonTapped), for: .touchUpInside)
    }
    
    private lazy var titleField: UITextField = UITextField().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .primaryText2
    }
    
    
    private lazy var addTodoButton: UIButton = UIButton().then {
        $0.contentMode = .center
        $0.imageView?.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        $0.setImage(UIImage(systemName: "plus.circle", withConfiguration: config), for: .normal)
        $0.addTarget(self, action: #selector(self.handleAddTodoButtonTapped), for: .touchUpInside)
    }
    
    private lazy var menuButton: UIButton = UIButton().then {
         $0.contentMode = .center
         $0.imageView?.contentMode = .scaleAspectFit
         $0.tintColor  = .thirdColor
         let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
         $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
         $0.addTarget(self, action: #selector(self.handleAddTodoButtonTapped), for: .touchUpInside)
     }
    
    var todoGroupBlock:Block! {
        didSet {
            let btnImage = todoGroupBlock.isExpand ? arrowDownImage : arrowRightImage
            arrowButton.setImage(btnImage, for: .normal)
            titleField.text = todoGroupBlock.text
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.selectionStyle = .none

        self.setupUI()
    }
    
    private func setupUI() {
        self.contentView.addSubview(arrowButton)
        arrowButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(10)
        }
        
        self.contentView.addSubview(titleField)
        self.contentView.addSubview(menuButton)
        titleField.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(arrowButton.snp.trailing).offset(6)
            make.trailing.equalTo(menuButton.snp.leading).offset(-3)
        }
        menuButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
            make.trailing.equalToSuperview().offset(-12)
        }
                
    }
}

extension TodoGroupCell {
    
    @objc private func handleArrowButtonTapped() {
        self.arrowButtonTapped?(self.todoGroupBlock)
    }
    
    @objc private func handleAddTodoButtonTapped() {
        self.menuButtonTapped?(self.menuButton,self.todoGroupBlock)
    }
}
