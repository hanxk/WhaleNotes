//
//  NoteEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/29.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class NoteEditorViewController: UITableViewController {
    enum EditorCellNodeType {
        case title
        case content
    }
    var cellNodeTypes:[EditorCellNodeType] = [.title,.content]
    
    private  var disposeBag = DisposeBag()
    var noteInfo:NoteInfo!
    private var model:NoteInfoViewModel!
    private var isNoteUpdated:Bool = false
    private var isKeyboardShow = false
    private var callbackNoteInfoEdited:((NoteInfo)->Void)?
    
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
        $0.isTranslucent = false
        $0.delegate = self
        let barAppearance =  UINavigationBarAppearance()
    //   barAppearance.configureWithDefaultBackground()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .white
            
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.registerNoteInfoEvent()
    }
    
    private func setupUI() {
        self.tableView.register(NoteTitleCell.self, forCellReuseIdentifier: "NoteTitleCell")
        self.tableView.register(NoteContentCell.self, forCellReuseIdentifier: "NoteContentCell")
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.contentInset = UIEdgeInsets(top: self.topbarHeight, left: 0, bottom: 0, right: 0)
        
        self.view.addSubview(myNavbar)
        myNavbar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor =  .white
        
        self.setupNavgationBar()
        self.registerTableViewTaped()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tryUpdateInputing()
        tryEmitUpdateEvent(isDelay: isKeyboardShow)
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    @objc func keyboardWillAppear() {
        //Do something here
        isKeyboardShow = true
    }

    @objc func keyboardWillDisappear() {
        //Do something here
        isKeyboardShow = false
    }
    
    @objc func appMovedToBackground() {
        tryUpdateInputing()
    }
    
    
    func callbackNoteInfoEdited(action: @escaping (NoteInfo) -> Void) {
        self.callbackNoteInfoEdited = action
    }
    
    func tryEmitUpdateEvent(isDelay:Bool)  {
        if isDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self  else {  return }
                
                if self.isNoteUpdated {
                   self.callbackNoteInfoEdited?(self.noteInfo)
                }
            }
            return
        }
        if self.isNoteUpdated {
            self.callbackNoteInfoEdited?(self.noteInfo)
        }
    }
    
}

extension NoteEditorViewController {
    private func setupNavgationBar() {
        
        let navItem = UINavigationItem()
        myNavbar.items = [navItem]
        myNavbar.tintColor = .iconColor
        self.createBackBarButton(forNavigationItem: navItem)
       
//        let tagButton = generateUIBarButtonItem(imageName: "tag", action:  #selector(tagIconTapped))
        
        let menuButton = generateUIBarButtonItem(imageName: "ellipsis", action:  #selector(menuIconTapped))
        navItem.rightBarButtonItems = [menuButton]
    }
    
    func generateUIBarButtonItem(imageName:String,action:Selector)  ->  UIBarButtonItem {
        return  UIBarButtonItem(image: UIImage(systemName: imageName,pointSize: 15,weight: .regular)?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: action).then {
            $0.tintColor = .iconColor
        }
    }
    
    func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
        
        let backButtonImage =  UIImage(systemName: "chevron.left", pointSize: 20, weight: .regular)
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        backButton.leftImage(image: backButtonImage!, renderMode: .alwaysOriginal)
//        backButton.backgroundColor = .red
           backButton.addTarget(self, action: #selector(backBarButtonTapped), for: .touchUpInside)
           let backBarButton = UIBarButtonItem(customView: backButton)
           navigationItem.leftBarButtonItems = [backBarButton]
    }
    
    @objc func backBarButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func menuIconTapped() {
    }
    
    
    @objc func tagIconTapped() {
    }
}

extension NoteEditorViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellNodeTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellNodeType = self.cellNodeTypes[indexPath.row]
        switch cellNodeType {
        case .title:
            let titleCellNode = tableView.dequeueReusableCell(withIdentifier: "NoteTitleCell", for: indexPath) as! NoteTitleCell
//            let titleCellNode = NoteTitleCellNode(title: self.noteInfo.note.title)
            titleCellNode.textView.text = self.noteInfo.note.title
            titleCellNode.textChanged {[weak self] (newText: String) in
                self?.refreshTableNode()
            }
            titleCellNode.textDidFinishEditing {[weak self] (newText: String) in
                self?.updateInputTitle(newText)
            }
            titleCellNode.textEnterkeyInput {[weak self] in
                self?.jump2ContentFirstWord()
            }
            return titleCellNode
        case .content:
            let contentCellNode = tableView.dequeueReusableCell(withIdentifier: "NoteContentCell", for: indexPath) as! NoteContentCell
            contentCellNode.textView.text = self.noteInfo.note.content
            contentCellNode.textChanged {[weak self] (newText: String) in
                self?.refreshTableNode()
            }
            let textView = contentCellNode.textView
            contentCellNode.textDidFinishEditing {[weak self,weak textView] (newText: String) in
                if let self = self,let textView = textView {
                   self.updateInputContent(newText,textView:textView)
                }
            }
            contentCellNode.tagTapped {[weak self] (tag: String) in
                self?.handleTagTapped(tag:tag)
            }
            return contentCellNode
        }
        
    }
    
    private func handleTagTapped(tag:String) {
        let isContains = self.noteInfo.tags.contains(where: { $0.title == tag })
        if isContains { return }
        
    }
    
    private func refreshTableNode() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
    
    private func updateInputContent(_ content:String,textView:MDTextView) {
        if self.noteInfo.note.content == content{ return }
        let noteTagTitles = self.noteInfo.tags
        
        let tagTitles = self.extractTags(tagRegex: textView.mdTextStorage.tagHightlighter.regex, text: content)
        
        let isEqual =  noteTagTitles.elementsEqual(tagTitles) { $0.title == $1 }
        if isEqual {
            self.model.updateNoteContent(content: content)
            return
        }
        // 提取标签并更新
        self.model.updateNoteContentAndTags(content: content, tagTitles: tagTitles)
        
        
        // 通知侧边栏刷新
        EventManager.shared.post(name: .Tag_CHANGED)
    }
    
    private func extractTags(tagRegex:NSRegularExpression,text:String) -> [String]  {
        var tags:[String] = []
        tagRegex.enumerateMatches(in: text,range:NSMakeRange(0, text.length)) {
            match, flags, stop in
            if  let  match = match {
                let  tagRange = match.range(at: 1)
                tags.append(text.substring(with: tagRange))
            }
        }
        
        var tagTitles:[String] = []
        for title in tags {
            //新增 parent tag
            let parentTitles = title.components(separatedBy: "/").dropLast()
            var pTitle = ""
            for (index,title) in parentTitles.enumerated() {
                if index > 0 { pTitle += "/" }
                pTitle += title
                tagTitles.append(pTitle)
            }
            tagTitles.append(title)
        }
        tagTitles = tagTitles.sorted { $0 < $1 }
        return tagTitles
    }
    
    private func updateInputTitle(_ title:String) {
        if self.noteInfo.note.title == title { return }
        self.model.updateNoteTitle(title: title)
    }
    
    func tryUpdateInputing() {
        if !isKeyboardShow { return }
        if let titleCelle = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as?  NoteTitleCell,
           titleCelle.textView.isFirstResponder
           {
            self.updateInputTitle(titleCelle.textView.text)
            return
        }
    }
    
    func jump2ContentFirstWord() {

    }
}



extension NoteEditorViewController {
    
    func registerNoteInfoEvent() {
        self.model = NoteInfoViewModel(noteInfo: noteInfo)
        self.model.noteInfoPub.subscribe(onNext: { [weak self] event in
            self?.handleNoteInfoEvent(event: event)
        }).disposed(by: disposeBag)
    }
    
    func handleNoteInfoEvent(event:NoteEditorEvent) {
        isNoteUpdated = true
        switch event {
        case .updated(let noteInfo):
            self.noteInfo = noteInfo
        }
    }
    
}

// MARK: 处理空白区域点击
extension NoteEditorViewController {
    private func registerTableViewTaped() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        tapGesture.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(tapGesture)
    }

    @objc func tableViewTapped(_ sender: UITapGestureRecognizer) {
        if sender.state != .ended {
            return
        }
        let touch = sender.location(in: self.tableView)
        if let _ = tableView.indexPathForRow(at: touch) { // 点击空白区域
            return
        }
        if let contentCell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? NoteContentCell {
            contentCell.textView.becomeFirstResponder()
        }
    }
}



extension NoteEditorViewController:UINavigationBarDelegate{
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
