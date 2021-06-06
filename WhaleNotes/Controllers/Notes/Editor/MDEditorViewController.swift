//
//  MDEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import RxSwift

enum MDEditorConfig {
    static let paddingH:CGFloat = 20
}
class MDEditorViewController: UIViewController {
    
    enum EditorCellNodeType {
        case title
        case content
        //        case tags
    }
    
    private  var disposeBag = DisposeBag()
    var noteInfo:NoteInfo!
    private var model:NoteInfoViewModel!
    private var needDismiss = false
    private var isNoteUpdated:Bool = false
    var cellNodeTypes:[EditorCellNodeType] = [.content]
    
    private var isKeyboardShow = false
    var isNewCreated = false
    
    private var callbackNoteInfoEdited:((NoteInfo)->Void)?
    
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
        $0.isTranslucent = false
        //        $0.delegate = self
        let barAppearance =  UINavigationBarAppearance()
        //   barAppearance.configureWithDefaultBackground()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .white
        
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    
    var contentCellIndex:Int {
        return self.cellNodeTypes.count-1
    }
    
    private lazy var tableView = ASTableNode().then {
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: bottomExtraSpace, right: 0)
        $0.view.allowsSelection = false
        $0.view.separatorStyle = .none
        $0.view.keyboardDismissMode = .none
    }
    
    
    lazy var bottomExtraSpace: CGFloat = 42.0 + 44
    let keyboardTop: CGFloat = 16
    
    var focusedTextView:UITextView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.registerNoteInfoEvent()
    }
    
    private func setupUI(){
        self.view.addSubview(tableView.view)
        tableView.view.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(0)
        }
        
        self.view.addSubview(myNavbar)
        myNavbar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor =  .white
        
        self.setupNavgationBar()
        self.registerTableViewTaped()
        
        
        if let cell = self.getNoteContentCellNode() {
            cell.textNode.textView.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    private func getNoteContentCellNode() -> NoteContentCellNode? {
        return self.tableView.nodeForRow(at: IndexPath(row: contentCellIndex, section: 0)) as?  NoteContentCellNode
    }
    private func getNoteTitleCell() -> NoteTitleCellNode? {
        return self.tableView.nodeForRow(at: IndexPath(row: 0, section: 0)) as?  NoteTitleCellNode
    }
    override func viewWillDisappear(_ animated: Bool) {
        tryUpdateInputing()
//        tryEmitUpdateEvent(isDelay: isKeyboardShow)
        print("viewWillDisappear")
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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

extension MDEditorViewController {
    
    func tryUpdateInputing() {
        guard let contentCellNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode else { return }
        var newNoteInfo = self.model.noteInfo!
        if isNoteUpdated {//
            self.callbackNoteInfoEdited?(newNoteInfo)
            return
        }
//        print("newNoteInfo.note.content \(newNoteInfo.note.content)")
//        print("contentCellNode.textNode.textView.text \(contentCellNode.textNode.textView.text)")
        let newContent = contentCellNode.textNode.textView.text!
        if newNoteInfo.note.content != newContent {
            newNoteInfo.note.content = newContent
            self.callbackNoteInfoEdited?(newNoteInfo)
        }
//        guard let contentCellNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode else { return }
//        if let contentCellNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode,
//           let newContent = contentCellNode.textNode.textView.text
//           {
//            var noteInfo = self.noteInfo!
//            if noteInfo.note.content != newContent {
//                noteInfo.note.content = newContent
//                self.callbackNoteInfoEdited?(noteInfo)
//            }
//        }
    }
}

//MARK: 键盘
extension MDEditorViewController {
    
    @objc func adjustForKeyboard(notification: Notification) {
        
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            var edgeInsets = tableView.contentInset
            edgeInsets.bottom = self.bottomExtraSpace
            tableView.contentInset = edgeInsets
            tableView.view.scrollIndicatorInsets  = .zero
            isKeyboardShow = false
        } else {
            isKeyboardShow = true
            let  offset = keyboardViewEndFrame.height - view.safeAreaInsets.bottom
            
            var edgeInsets = tableView.contentInset
            edgeInsets.bottom = offset + keyboardTop
            tableView.contentInset = edgeInsets
            
            tableView.view.scrollIndicatorInsets  =  UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0)
            
            if let focusedTextView = self.focusedTextView {
              self.scrollToCursorPositionIfBelowKeyboard(textView:focusedTextView)
            }
        }
    }
    
    private func scrollToCursorPositionIfBelowKeyboard(textView:UITextView,animated:Bool = true) {
        
        let pointInTable:CGPoint = textView.superview!.convert(textView.frame.origin, to: self.tableView.view)
        let originY = pointInTable.y
        
        if let selectedRange = textView.selectedTextRange {
            var caret = textView.caretRect(for: selectedRange.start)
            caret.y =  caret.y + originY + self.keyboardTop
            self.tableView.view.scrollRectToVisible(caret, animated: animated)
        }
    }
    
    
}


extension MDEditorViewController {
    
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
            if needDismiss {
                self.callbackNoteInfoEdited?(noteInfo)
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.noteInfo = noteInfo
        }
    }
    
}


// MARK: 处理空白区域点击
extension MDEditorViewController: UIGestureRecognizerDelegate {
    private func registerTableViewTaped() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        self.tableView.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tableViewTapped(_ sender: UITapGestureRecognizer) {
        
        if sender.state != .ended {
            return
        }
//        if self.noteInfo.status == .trash {
//            return
//        }
        
        let touch = sender.location(in: self.tableView.view)
        if let _ = tableView.indexPathForRow(at: touch) { // 点击空白区域
            return
        }
        if let contentCell = self.tableView.nodeForRow(at: IndexPath(row: self.cellNodeTypes.count-1, section: 0)) as? NoteContentCellNode {
            contentCell.textNode.becomeFirstResponder()
        }
    }
}
//MARK: setupNavgationBar
extension MDEditorViewController {
    private func setupNavgationBar() {
        
        let navItem = UINavigationItem()
        myNavbar.items = [navItem]
        myNavbar.tintColor = .toolbarTint
        
        func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
            let backButtonImage =  UIImage(systemName: "camera",pointSize: 18)?.withTintColor(.toolbarTint).withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0))
            let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            backButton.leftImage(image: backButtonImage!, renderMode: .alwaysOriginal)
            backButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
            let backBarButton = UIBarButtonItem(customView: backButton)
            navigationItem.leftBarButtonItems = [backBarButton]
        }
        
        createBackBarButton(forNavigationItem: navItem)
        
//        let menuButton = generateUIBarButtonItem(imageName: "ellipsis", action:  #selector(saveIconTapped))
        
        let savevButton = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(saveIconTapped))
        savevButton.tintColor = .brand
        
        navItem.rightBarButtonItems = [savevButton]
        
//        let closeButton =  UIButton().then {
//            $0.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
//            let image = UIImage(systemName: "chevron.compact.down", pointSize: 44)?.withRenderingMode(.alwaysTemplate)
//            $0.setImage(image, for: .normal)
//            $0.tintColor = .toolbarTint
//            $0.addTarget(self, action: #selector(saveIconTapped), for: .touchUpInside)
//        }
//        navItem.titleView = closeButton
        
    }
    
    func generateUIBarButtonItem(imageName:String,iconSize:CGFloat = 15,action:Selector)  ->  UIBarButtonItem {
        return  UIBarButtonItem(image: UIImage(systemName: imageName,pointSize: iconSize,weight: .regular)?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: action).then {
            $0.tintColor = .iconColor
        }
    }
    
    
    @objc func cameraButtonTapped() {
        
    }
    
    @objc func saveIconTapped() {
        guard let cell = self.getNoteContentCellNode() else { return }
        let content = cell.textNode.textView.text ?? ""
        if self.noteInfo.note.content == content{
            if isNewCreated { // 删除
                self.deleteNoteInfo()
                return
            }
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.needDismiss = true
        updateInputContent(content)
    }
    @objc func tagIconTapped() {
    }
}


extension MDEditorViewController:ASTableDelegate {
    
}

extension MDEditorViewController:ASTableDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellNodeTypes.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNodeType = self.cellNodeTypes[indexPath.row]
        switch cellNodeType {
        case .title:
            let titleCellNode = NoteTitleCellNode(title: self.noteInfo.note.title)
            titleCellNode.textChanged {[weak titleCellNode] (newText: String) in
                if let titleCellNode = titleCellNode {
                    self.refreshTableNode(node: titleCellNode)
                }
            }
            titleCellNode.textDidFinishEditing {[weak self] (newText: String) in
                self?.updateInputTitle(newText)
            }
            titleCellNode.textEnterkeyInput {[weak self] in
                self?.jump2ContentFirstWord()
            }
            titleCellNode.textShouldBeginEditing {[weak self] (textView: UITextView) in
//                self?.scrollToCursorPositionIfBelowKeyboard(textView: textView)
                self?.focusedTextView = textView
            }
//            titleCellNode.titleNode.textView.isEditable = self.noteInfo.status != .trash
            return titleCellNode
        case .content:
            let contentCellNode = NoteContentCellNode(title: self.noteInfo.note.content)
            contentCellNode.textChanged {[weak contentCellNode] (newText: String) in
                if let contentCellNode = contentCellNode {
                    self.refreshTableNode(node: contentCellNode)
                }
            }
            contentCellNode.textDidFinishEditing {[weak self] (newText: String) in
//                self?.updateInputContent(newText)
            }
            contentCellNode.textShouldBeginEditing {[weak self] (textView: UITextView) in
                self?.focusedTextView = textView
            }
            contentCellNode.textShouldBeginEditing {[weak self] (textView: UITextView) in
                self?.focusedTextView = textView
            }
            contentCellNode.saveButtonTapped {[weak self]  in
//                self?.dismiss(animated: true, completion: nil)
                self?.saveIconTapped()
            }
//            textView.inputAccessoryView = keyboardView
            //        if isEditable   {
            //            let keyboardView = MDKeyboardView()
            //            keyboardView.delegate = self
            //            textView.inputAccessoryView = keyboardView
            //        }
//            contentCellNode.textNode.textView.isEditable = self.noteInfo.status != .trash
            return contentCellNode
        }
    }
    
    private func updateInputContent(_ content:String) {
        let noteTagTitles = self.noteInfo.tags
        let tagTitles = MDEditorViewController.extractTags(text: content)

        let isTagNotChange =  noteTagTitles.elementsEqual(tagTitles) { $0.title == $1 }
        if isTagNotChange { // 只更新内容
            self.model.updateNoteContent(content: content)
            return
        }
        // 提取标签并更新
        self.model.updateNoteContentAndTags(content: content, tagTitles: tagTitles)

        // 通知侧边栏刷新
        EventManager.shared.post(name: .Tag_UPDATED)
    }
    
    
    func deleteNoteInfo() {
        NoteRepo.shared.deleteNote(self.noteInfo)
        .subscribe(onNext: { _  in
            self.dismiss(animated: true, completion: nil)
        },onError: {
            Logger.error($0)
        })
        .disposed(by: disposeBag)
    }
    
    static func extractTags(text:String) -> [String]  {
        let tagRegex = regexFromPattern(pattern: MDTagHighlighter.regexStr)
        var tags:[String] = []
        tagRegex.enumerateMatches(in: text,range:NSMakeRange(0, text.length)) {
            match, flags, stop in
            if  let  match = match {
                let  tagRange = match.range(at: 0)
                if tagRange.length > 0 {
                    let tag = text.substring(with: tagRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    let tagTitles = tag.split("#")
                    if tagTitles.count > 0 {
                        let tagValue = tagTitles[tagTitles.count-1]
                        tags.append(tagValue)
                    }
                    
//                    if let hashTagIndex = tag.firstIndex(of: "#") {
//                        let range = tag.startIndex..<hashTagIndex
//                        tag = String(tag[range])
//                    }
                    
                }
            }
        }
        var tagTitles:[String] = []
        for title in tags {
            //新增 parent tag
            let parentTitles = title.components(separatedBy: "/")
            var pTitle = ""
            for (index,title) in parentTitles.enumerated() {
                let tagTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if tagTitle.isEmpty {
                    continue
                }
                if index > 0 { pTitle += "/" }
                pTitle += tagTitle
                tagTitles.append(pTitle)
            }
        }
        tagTitles = tagTitles.sorted { $0 < $1 }
        return tagTitles
            
    }
    
    
    static func extractTagsFromTitle(title:String) -> [String]  {
        if !"#\(title)".match(pattern: MDTagHighlighter.regexStr) {
            fatalError("extractTagsFromTitle: \(title)  --- > 不合法")
        }
        var tagTitles:[String] = []
        let parentTitles = title.components(separatedBy: "/").dropLast()
        var pTitle = ""
        for (index,title) in parentTitles.enumerated() {
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            if pTitle.isNumber() { pTitle += "/" }
            pTitle += title
            tagTitles.append(pTitle)
        }
        tagTitles.append(title)
        return tagTitles
    }
    
    private func updateInputTitle(_ title:String) {
        if self.noteInfo.note.title == title { return }
        self.model.updateNoteTitle(title: title)
    }
    
    
    private func refreshTableNode(node:ASCellNode) {
        UIView.setAnimationsEnabled(false)
        self.tableView.performBatch(animated: false) {
            node.setNeedsLayout()
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + node.defaultLayoutTransitionDuration) {
                UIView.setAnimationsEnabled(true)
            }
            
            if self.isKeyboardShow {
                if let focusedTextView = self.focusedTextView {
                    self.scrollToCursorPositionIfBelowKeyboard(textView:focusedTextView,animated:false)
                }
            }
            
        }
        
        
    }
    
    func jump2ContentFirstWord() {
        if let contentCelleNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode {
            //            contentCelleNode.contentNode.becomeFirstResponder()
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //                // your code here
            //                contentCelleNode.contentNode.selectedRange = NSMakeRange(0, 0)
            //            }
        }
    }
}
