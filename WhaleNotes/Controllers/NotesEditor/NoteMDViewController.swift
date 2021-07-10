//
//  NoteMDViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class NoteMDViewController:UIViewController {
    
    private var textView:UITextView!
    private var highlighter:MDTextViewWrapper!
    
    private var model:NoteInfoViewModel!
    var callbackNoteInfoEdited:((NoteInfo)->Void)?
    
    var isNewCreated = false
    var noteInfo:NoteInfo!
    
    private let disposeBag = DisposeBag()
    private var isNoteUpdated:Bool = false
    private var needDismiss = false
    

    private lazy var keyboardView = MDKeyboardView().then {
        $0.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        
        textView.font = MDStyleConfig.normalFont
        self.textView.text = noteInfo.content
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        self.registerNoteInfoEvent()
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        if noteInfo.content != self.textView.text {
//            self.updateInputContent(self.textView.text)
            
        }
    }
    
    private func setup() {
        let left:CGFloat = 20
        let top = left + window.safeAreaInsets.top
        textView = MyTextView(frame: self.view.frame).then {
            $0.contentInset = UIEdgeInsets(top: top, left: left, bottom: left, right: left)
            $0.inputAccessoryView = keyboardView
            $0.isScrollEnabled = true
            $0.isUserInteractionEnabled = true
        }
        self.view.addSubview(textView)
        
        highlighter = MDTextViewWrapper(textView: textView)
        textView.becomeFirstResponder()
    }
}

extension NoteMDViewController {
    
    func registerNoteInfoEvent() {
        self.model = NoteInfoViewModel(noteInfo: noteInfo)
        self.model.noteInfoPub.subscribe(onNext: { [weak self] event in
            self?.handleNoteInfoEvent(event: event)
        }).disposed(by: disposeBag)
    }
    
    func handleNoteInfoEvent(event:NoteEditorEvent) {
        isNoteUpdated = true
//        switch event {
//        case .updated(let noteInfo):
//            if needDismiss {
//                self.callbackNoteInfoEdited?(noteInfo)
//                self.dismiss(animated: true, completion: nil)
//                return
//            }
//            self.noteInfo = noteInfo
//        }
    }
    
}

extension NoteMDViewController:MDKeyboarActionDelegate {
    func headerButtonTapped() {
        self.highlighter.changeHeaderLine()
    }
    func boldButtonTapped() {
        self.highlighter.change2Bold()
    }
    
    func tagButtonTapped() {
        self.textView.insertText(HASHTAG)
    }
    
    func listButtonTapped() {
        self.highlighter.changeCurrentLine2List()
    }

    func orderListButtonTapped() {
        self.highlighter.changeCurrentLine2OrderList()
    }

    func keyboardButtonTapped() {
        let content = self.textView.text
        if self.noteInfo.note.content == content{
            if isNewCreated { // 删除
                self.deleteNoteInfo()
                return
            }
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.needDismiss = true
//        self.updateInputContent(self.textView.text)
    }
}


extension NoteMDViewController {
    
//    private func updateInputContent(_ content:String) {
//        
//        let noteTagTitles = self.noteInfo.tags
//        let tagTitles = MDEditorViewController.extractTags(text: content)
//
//        let isTagNotChange =  noteTagTitles.elementsEqual(tagTitles) { $0.title == $1 }
//        if isTagNotChange { // 只更新内容
//            self.model.updateNoteContent(content: content)
//            return
//        }
//        // 提取标签并更新
//        self.model.updateNoteContentAndTags(content: content, tagTitles: tagTitles)
//
//        // 通知侧边栏刷新
//        EventManager.shared.post(name: .Tag_UPDATED)
//    }
    
    func deleteNoteInfo() {
        NoteRepo.shared.deleteNote(self.noteInfo)
        .subscribe(onNext: { _  in
            self.dismiss(animated: true, completion: nil)
        },onError: {
            Logger.error($0)
        })
        .disposed(by: disposeBag)
    }
}
