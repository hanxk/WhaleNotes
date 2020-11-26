//
//  CardDetailViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

protocol CardEditorView:Any {
     
}
class CardEditorViewController: UIViewController {
    var editorView:BaseCardEditorView!
    var viewModel:CardEditorViewModel!
    var isNew = false
    
    
    private lazy var navBar:UINavigationBar = UINavigationBar() .then{
        $0.isTranslucent = false
        $0.delegate = self
        let barAppearance =  UINavigationBarAppearance()
    //   barAppearance.configureWithDefaultBackground()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .white
            
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    
    private lazy var titleTextField =  TitleTextField(frame:  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )).then {
        $0.textAlignment = .center
        $0.placeholder = "标题"
        $0.clipsToBounds = true
        $0.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )
        $0.backgroundColor = .clear
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .primaryText
        $0.delegate = self
    }
    
    private var bg:UIColor!
    
    var updateEvent:EditorUpdateEvent!
    var updateCallback:((EditorUpdateEvent) -> Void)? = nil
    
    private  var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.registerViewModel()
        titleTextField.text = viewModel.blockInfo.title
        self.navigationItem.titleView = titleTextField
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tryResignResponder()
        super.viewWillDisappear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            print("push了............")
            if let event = self?.updateEvent {
                self?.updateCallback?(event)
            }
        }
    }
    
    private func registerViewModel() {
        viewModel.noteInfoPub.subscribe { [weak self] in
            self?.handleEditorUpdateEvent(event: $0)
        } onError: {
            Logger.error($0)
        }.disposed(by: disposeBag)
    }
    
    private func tryResignResponder() {
        titleTextField.endEditing(true)
        self.view.endEditing(true)
    }
    
    private func setupKeyboard() {
        if !isNew { return }
        if let noteView = editorView as? NoteView {
            noteView.textView.becomeFirstResponder()
            return
        }
        if let todoListView = editorView as? TodoBlockEditorView {
            todoListView.todoBecomeFirstResponder()
        }
    }
    
}

extension CardEditorViewController:UINavigationBarDelegate{
    
    private func setupUI(){
        
        editorView = generateContentView()
        
        self.view.addSubview(editorView)
        editorView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(self.topbarHeight)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        self.view.addSubview(navBar)
        navBar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        
        
        self.bg = .white
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor =  .white
        
        self.setupNavgationBar()
    }
    
    private func setupNavgationBar() {
        
        let navItem = UINavigationItem()
        navBar.items = [navItem]
        navBar.tintColor = .iconColor
        self.createBackBarButton(forNavigationItem: navItem)
        navItem.titleView = titleTextField
        
        
        let pen =  UIBarButtonItem(image: UIImage(systemName: "pencil.circle"), style: .plain, target: self, action: #selector(infoIconTapped))
        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(infoIconTapped))
        navItem.rightBarButtonItems = [more,pen]
        
    }
    
    @objc func infoIconTapped() {
        let vc = CardSettingViewController()
        vc.viewModel = self.viewModel
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
        
        let backButtonImage =  UIImage(systemName: "chevron.left", pointSize: 20, weight: .regular)
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        backButton.leftImage(image: backButtonImage!, renderMode: .alwaysOriginal)
//        backButton.backgroundColor = .red
           backButton.addTarget(self, action: #selector(CardEditorViewController.backBarButtonTapped), for: .touchUpInside)
           let backBarButton = UIBarButtonItem(customView: backButton)
           navigationItem.leftBarButtonItems = [backBarButton]
    }
    
    @objc func backBarButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}


extension CardEditorViewController {
    
    func handleEditorUpdateEvent(event:EditorUpdateEvent) {
        self.updateEvent = event
        switch event {
        case .updated:
            break
        case .statusChanged:
            break
        case .backgroundChanged:
            break
        case .moved:
            break
        case .delete:
            self.navigationController?.popViewController(animated: true)
            break
        }
    }
}


extension CardEditorViewController {
    private func generateContentView() -> BaseCardEditorView {
        let blockInfo = viewModel.blockInfo
        switch blockInfo.block.type {
        case .note:
            return NoteView(viewModel: viewModel)
        case .image:
            return ImageBlockView(imageBlock: blockInfo)
        case .todo_list:
            let todoListView = TodoBlockEditorView(viewModel: viewModel)
            todoListView.callbackTryHideKeyboard = {
                 self.tryResignResponder()
            }
            return todoListView
        default:
            return BaseCardEditorView(frame: .zero)
        }
    }
    
}

//MARK: title textfield delegate
extension CardEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.titleTextField.resignFirstResponder()
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let title = textField.text ?? ""
        if  title != viewModel.blockInfo.title {
            viewModel.update(title: title)
        }
        return true
    }

}
