//
//  TodoGroupCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/15.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoGroupCell: UITableViewCell {
    
    static let CELL_HEIGHT:CGFloat = 28
    
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
        $0.delegate = self
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
    var note:Note!
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
//        self.backgroundColor = .red
        self.setupUI()
    }
    
    private func setupUI() {
        self.contentView.addSubview(arrowButton)
        arrowButton.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(TodoGroupCell.CELL_HEIGHT)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(10)
        }
        
        self.contentView.addSubview(titleField)
        self.contentView.addSubview(menuButton)
        titleField.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(arrowButton.snp.trailing).offset(4)
            make.trailing.equalTo(menuButton.snp.leading).offset(-3)
        }
        menuButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(TodoGroupCell.CELL_HEIGHT)
            make.width.equalTo(TodoGroupCell.CELL_HEIGHT+4)
            make.trailing.equalToSuperview().offset(-10)
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

extension TodoGroupCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if let enterkeyTapped = self.enterkeyTapped {
//            enterkeyTapped(textField.text ?? "")
//            return false
//        }
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        var title = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if title.isEmpty {
            title = "清单"
            textField.text = title
        }
        if  title != todoGroupBlock.text {
            DBManager.sharedInstance.update(note: self.note) {
                todoGroupBlock.text =  title
            }
        }
        return true
    }
}
