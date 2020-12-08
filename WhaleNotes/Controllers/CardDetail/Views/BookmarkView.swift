//
//  BookmarkView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/1.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import WebKit

class BookmarkView: BaseCardEditorView {
    
    private var block:BlockInfo!
    private var webView: WKWebView = WKWebView()
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    /// The observation object for the progress of the web view (we only receive notifications until it is deallocated).
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    init(block:BlockInfo) {
        super.init(frame: .zero)
        self.block = block
        
        self.initializeUI()
        setupEstimatedProgressObserver()
        
        if let urlStr = block.blockBookmarkProperties?.link,
           let url = URL(string: urlStr) {
            webView.navigationDelegate = self
            webView.load(URLRequest(url: url))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        addSubview(webView)
        webView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        addSubview(progressView)
        progressView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(2)
        }
    }
    
    private func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }
}

extension BookmarkView: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        if progressView.isHidden {
            // Make sure our animation is visible.
            progressView.isHidden = false
        }
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 1.0
        })
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 0.0
                       },
                       completion: { isFinished in
                           // Update `isHidden` flag accordingly:
                           //  - set to `true` in case animation was completly finished.
                           //  - set to `false` in case animation was interrupted, e.g. due to starting of another animation.
                           self.progressView.isHidden = isFinished
        })
    }
}
