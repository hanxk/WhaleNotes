//
//  MyToolbar.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

enum ToolbarConstants {
    static let height:CGFloat = 50
    static let buttonPadding:CGFloat =  NotesViewConstants.cellHorizontalSpace
}

class HomeToolbar: BaseToolbar {
    
    var callbackSearchButtonTapped:((UIButton) -> Void)!
    var callbackAddButtonTapped:((UIButton) -> Void)!
    var callbackMoreButtonTapped:((UIButton) -> Void)!
    
    lazy var searchButton: UIButton = UIButton().then {
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: ToolbarConstants.buttonPadding, bottom: 0, right:  ToolbarConstants.buttonPadding)
        $0.tintColor = .toolbarIcon
        $0.setImage(generateUIBarButtonImage(imageName: "magnifyingglass.circle"), for: .normal)
        $0.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }
    
    lazy var addButton: UIButton = UIButton().then {
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: ToolbarConstants.buttonPadding, bottom: 0, right:  ToolbarConstants.buttonPadding)
        $0.tintColor = .toolbarIcon
        $0.setImage(generateUIBarButtonImage(imageName: "plus.circle.fill",imageSize: 24,weight: .medium), for: .normal)
        $0.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    lazy var moreButton: UIButton = UIButton().then {
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: ToolbarConstants.buttonPadding, bottom: 0, right:  ToolbarConstants.buttonPadding)
        $0.tintColor = .toolbarIcon
        $0.setImage(generateUIBarButtonImage(imageName: "ellipsis.circle"), for: .normal)
        $0.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
//        self.tintColor = .toolbarIcon
        self.backgroundColor = .toolbarBg
        addSubview(searchButton)
        searchButton.snp.makeConstraints { (make) in
            make.height.equalTo(ToolbarConstants.height)
            make.leading.equalToSuperview()
        }
        
        
        addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.height.equalTo(ToolbarConstants.height)
            make.center.equalToSuperview()
        }
        
        
        addSubview(moreButton)
        moreButton.snp.makeConstraints { (make) in
            make.height.equalTo(ToolbarConstants.height)
            make.trailing.equalToSuperview()
        }

    }
}

extension HomeToolbar {
    
    @objc func searchButtonTapped (sender:UIButton) {
        self.callbackSearchButtonTapped(sender)
    }
    
    @objc func addButtonTapped (sender:UIButton) {
        self.callbackAddButtonTapped(sender)
    }
    
    @objc func moreButtonTapped (sender:UIButton) {
        self.callbackMoreButtonTapped(sender)
        
    }
    
}
