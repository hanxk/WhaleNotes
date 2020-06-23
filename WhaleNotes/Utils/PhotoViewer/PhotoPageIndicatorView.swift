//
//  PhotoPageIndicatorView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/22.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import JXPhotoBrowser
class PhotoPageIndicatorView: UILabel, JXPhotoBrowserPageIndicator {
    
    ///  页码与顶部的距离
    open lazy var topPadding: CGFloat = {
        let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
        return keyWindow?.safeAreaInsets.top ?? 20
    }()
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        config()
    }
    
    private func config() {
        font = UIFont.systemFont(ofSize: 17)
        textAlignment = .center
        textColor = UIColor.white
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        layer.masksToBounds = true
    }
    
    public func setup(with browser: JXPhotoBrowser) {
        
    }
    
    private var total: Int = 0
    
    public func reloadData(numberOfItems: Int, pageIndex: Int) {
        total = numberOfItems
        text = "\(pageIndex + 1) / \(total)"
        sizeToFit()
        frame.size.width += frame.height
        layer.cornerRadius = frame.height / 2
        if let view = superview {
            center.x = view.bounds.width / 2
            frame.origin.y = topPadding
        }
        isHidden = numberOfItems == 0 
    }
    
    public func didChanged(pageIndex: Int) {
        text = "\(pageIndex + 1) / \(total)"
    }
    
}
