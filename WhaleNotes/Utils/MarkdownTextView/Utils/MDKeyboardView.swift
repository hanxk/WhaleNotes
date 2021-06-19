//
//  MDKeyboardView.swift
//  MarkdownTextView
//
//  Created by hanxk on 2020/12/28.
//  Copyright © 2020 Indragie Karunaratne. All rights reserved.
//

import UIKit


fileprivate var btnWidth: CGFloat = {
    return isPad ? 50 : 44
}()

fileprivate var btnHeight: CGFloat = {
    return isPad ? 52 : 46
}()

fileprivate var spacing: CGFloat = {
    return 6
}()
fileprivate var vSpacing: CGFloat = {
    return 0
}()

class MDKeyboardView: UIView {
    
    let scrollView = UIScrollView()
    private var items:[(String,Selector)] = [
        ("grid",#selector(tagButtonTapped)),
//        ("h.circle",#selector(headerButtonTapped)),
        ("bold",#selector(boldButtonTapped)),
        ("list.bullet",#selector(listButtonTapped)),
        ("list.number",#selector(orderListButtonTapped))
    ]
    
    weak var delegate:MDKeyboarActionDelegate?
    
    init(hasActions:Bool = true) {
        super.init(frame: CGRect(x: 0, y: 0, width:windowWidth, height: btnHeight))
        self.setupButtons(hasActions)
        self.backgroundColor = .white
//        self.layer.shadowColor = UIColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1).cgColor
//        self.layer.shadowOpacity = 1
//        self.layer.shadowRadius = 0
//        self.layer.shadowOffset = CGSize(width: 0, height: -1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons(_ hasActions:Bool) {
        
        let keyboardButton =  UIButton().then {
            $0.frame = CGRect(x: 0, y: 0, width: 100, height: btnHeight)
            $0.setTitle("完成", for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            $0.setTitleColor(.brand, for: .normal)
            $0.addTarget(self, action: #selector(keyboardButtonTapped), for: .touchUpInside)
        }
        addSubview(keyboardButton)
        
        if hasActions {
            var x:CGFloat = 4
            for i in 0..<items.count {
                let button = makeButton(btnParam:items[i])
                button.tag = i
                button.frame = CGRect(x: x, y: vSpacing, width: btnWidth, height: btnHeight)
                x += (btnWidth+spacing)
                self.scrollView.addSubview(button)
            }
            scrollView.contentSize = CGSize(width: CGFloat(items.count) * btnWidth+CGFloat(items.count+1)*spacing, height: btnHeight)
            
            addSubview(scrollView)
            
            scrollView.snp.makeConstraints {
                $0.height.equalToSuperview()
                $0.leading.equalToSuperview()
                $0.trailing.equalTo(keyboardButton.snp.leading)
            }
        }
        
        
        
        
        keyboardButton.snp.makeConstraints {
            $0.height.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-10)
            $0.width.equalTo(btnWidth + spacing)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
    }
    
    private func makeButton(btnParam:(String,Selector),pointSize:CGFloat = 20) -> UIButton {
        let button = UIButton(type: .custom)
//        button.backgroundColor = UIColor(hexString: "#EFEEF1")
        button.layer.cornerRadius = 4
        button.setImage(UIImage(systemName: btnParam.0,pointSize: pointSize,weight: .medium)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor(hexString: "#414141")
        button.addTarget(self, action: btnParam.1, for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: isPad ? 18 : 15)
        return button
    }
}

extension MDKeyboardView {
    @objc fileprivate func headerButtonTapped() {
        delegate?.headerButtonTapped()
    }
    @objc fileprivate func boldButtonTapped() {
        delegate?.boldButtonTapped()
    }
    @objc fileprivate func tagButtonTapped() {
        delegate?.tagButtonTapped()
    }
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
    func headerButtonTapped()
    func boldButtonTapped()
    func tagButtonTapped()
    func listButtonTapped()
    func orderListButtonTapped()
    func keyboardButtonTapped()
}


extension MDKeyboardView {
    
}
