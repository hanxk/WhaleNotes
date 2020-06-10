//
//  BaseAlertViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/8.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BaseAlertViewController: UIViewController {
    
    var alertTitle:String = "" {
        didSet {
            self.titleLabel.isHidden = alertTitle.isEmpty
            self.titleLabel.text = alertTitle
        }
    }
    
    var positiveButtonText:String = "确定" {
        didSet {
           positiveBtn.setTitle(positiveButtonText, for: .normal)
        }
    }
    var isPositiveDestructive:Bool = false {
        didSet {
            if isPositiveDestructive {
                positiveBtn.setTitleColor(.red, for: .normal)
            }else {
                 positiveBtn.setTitleColor(.brand, for: .normal)
            }
            
        }
    }
    
    var negativeButtonText:String = "取消" {
        didSet {
           cancelBtn.setTitle(negativeButtonText, for: .normal)
        }
    }
    
    var alertHeight:CGFloat  {
        return 175
    }
    
    
    let contentView = UIView()
    
    
    lazy var  alertView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
    }
    
    private lazy var  titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .black
        $0.text = alertTitle
    }
    
   
    private lazy var cancelBtn = UIButton().then {
        $0.setTitle(negativeButtonText, for: .normal)
        $0.setTitleColor(UIColor.init(hexString: "#666666"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.addTarget(self, action: #selector(self.cancelBtnTapped), for: .touchUpInside)
    }
    
    
    private lazy var positiveBtn = UIButton().then {
        $0.setTitle(positiveButtonText, for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        $0.addTarget(self, action: #selector(self.positiveBtnTapped), for: .touchUpInside)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupUI() {
        
       
        let bottom = UIScreen.main.bounds.height / 2 - alertHeight/2
        
        self.view.addSubview(alertView)
        alertView.snp.makeConstraints {
            $0.width.equalTo(290)
            $0.height.equalTo(alertHeight)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-bottom)
        }
        //        alertView.isHidden = true
        
        // 标题
        alertView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(16)
        }
        self.titleLabel.isHidden = alertTitle.isEmpty
        
        
        //添加 contentview
        alertView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
            $0.width.equalToSuperview()
        }
               
        alertView.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints {
            $0.top.equalTo(contentView.snp.bottom).offset(5)
            $0.height.equalTo(44)
            $0.width.equalToSuperview().dividedBy(2)
            $0.bottom.equalToSuperview()
            $0.leading.equalToSuperview()
        }
        
        let borderColor = UIColor.init(hexString: "#F5F6F7")
        cancelBtn.addTopBorder(with: borderColor, andWidth: 1)
        cancelBtn.addRightBorder(with: borderColor, andWidth: 1)
        
        alertView.addSubview(positiveBtn)
        positiveBtn.snp.makeConstraints {
            $0.height.equalTo(cancelBtn.snp.height)
            $0.width.equalTo(cancelBtn.snp.width)
            $0.leading.equalTo(cancelBtn.snp.trailing)
            $0.bottom.equalToSuperview()
        }
        
        positiveBtn.addTopBorder(with: borderColor, andWidth: 1)
        
    }
    
    
    @objc func cancelBtnTapped() {
        dismiss()
    }
    
    @objc func positiveBtnTapped() {
        dismiss()
    }
    
    func dismiss() {
        self.dismiss(animated: false, completion: nil)
    }
}
