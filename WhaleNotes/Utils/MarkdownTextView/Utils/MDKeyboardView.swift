//
//  MDKeyboardView.swift
//  MarkdownTextView
//
//  Created by hanxk on 2020/12/28.
//  Copyright © 2020 Indragie Karunaratne. All rights reserved.
//

import UIKit


fileprivate var width: CGFloat = {
    return isPad ? 50 : 40
}()

fileprivate var spacing: CGFloat = {
    return 10
}()
fileprivate var vSpacing: CGFloat = {
    return 0
}()

class MDKeyboardView: UIView {
    
    let scrollView = UIScrollView()
    
    private var items:[(String,Selector)] = [
        ("list.bullet",#selector(listButtonTapped)),
        ("list.number",#selector(orderListButtonTapped))
    ]
    
    weak var delegate:MDKeyboarActionDelegate?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width:windowWidth, height: width))
        self.setupButtons()
        
        
        self.backgroundColor = .white
//        self.layer.shadowColor = UIColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1).cgColor
//        self.layer.shadowOpacity = 1
//        self.layer.shadowRadius = 0
//        self.layer.shadowOffset = CGSize(width: 0, height: -1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons() {
        var x:CGFloat = 0
        let buttonW = width-vSpacing*2
        for i in 0..<items.count {
            let button = makeButton(btnParam:items[i])
            button.tag = i
            x += (CGFloat(i) * width + spacing)
            button.frame = CGRect(x: x, y: vSpacing, width: buttonW, height: buttonW)
            self.scrollView.addSubview(button)
        }
        scrollView.contentSize = CGSize(width: CGFloat(items.count) * width+CGFloat(items.count+1)*spacing, height: width)
        
        addSubview(scrollView)
        let keyboardButton = makeButton(btnParam:("checkmark",#selector(keyboardButtonTapped)),pointSize: 18)
        addSubview(keyboardButton)
        
        scrollView.snp.makeConstraints {
            $0.height.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(keyboardButton.snp.leading)
        }
        
        keyboardButton.snp.makeConstraints {
            $0.height.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.width.equalTo(buttonW + spacing)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
    }
    
    private func makeButton(btnParam:(String,Selector),pointSize:CGFloat = 22) -> UIButton {
        let button = UIButton(type: .custom)
//        button.backgroundColor = UIColor(hexString: "#EFEEF1")
        button.layer.cornerRadius = 4
        button.setImage(UIImage(systemName: btnParam.0,pointSize: pointSize,weight: .regular)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor(hexString: "#414141")
        button.addTarget(self, action: btnParam.1, for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: isPad ? 18 : 16)
        return button
    }
}

extension MDKeyboardView {
    @objc fileprivate func listButtonTapped() {
        delegate?.listButtonTapped()
    }
    @objc fileprivate func orderListButtonTapped() {
        delegate?.orderListButtonTapped()
    }
    @objc fileprivate func keyboardButtonTapped() {
        delegate?.keyboardButtonTapped()
    }
}

protocol MDKeyboarActionDelegate: AnyObject {
    func listButtonTapped()
    func orderListButtonTapped()
    func keyboardButtonTapped()
}


extension MDKeyboardView {
    
}
