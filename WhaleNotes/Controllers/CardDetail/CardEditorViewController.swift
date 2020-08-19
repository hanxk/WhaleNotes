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
    
    lazy var titleTextField =  TitleTextField(frame:  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )).then {
        $0.textAlignment = .center
        $0.placeholder = "标题"
        $0.clipsToBounds = true
        $0.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )
        $0.backgroundColor = .clear
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .primaryText
        $0.delegate = self
    }
    
    private var bg:UIColor! {
        didSet {
//            let bgColor = UIColor(hexString: bg)
            self.navigationItem.titleView = titleTextField
            navigationController?.navigationBar.barTintColor = bg
            self.view.backgroundColor =  bg
        }
    }
    
    var updateEvent:EditorUpdateEvent!
    var updateCallback:((EditorUpdateEvent) -> Void)? = nil
    
    private  var disposeBag = DisposeBag()
    
    override func loadView() {
        editorView = generateContentView()
        view = editorView
        self.bg = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerViewModel()
        titleTextField.text = viewModel.blockInfo.title
        self.navigationItem.titleView = titleTextField
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        titleTextField.endEditing(true)
        self.view.endEditing(true)
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
            print("更新了............")
            self?.handleEditorUpdateEvent(event: $0)
        } onError: {
            Logger.error($0)
        }.disposed(by: disposeBag)
    }
    
    private func setupKeyboard() {
        if isNew && view is NoteView {
            (view as! NoteView).textView.becomeFirstResponder()
        }
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
