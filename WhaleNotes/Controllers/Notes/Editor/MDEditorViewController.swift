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
        case media
        //        case tags
    }
    
    private  var disposeBag = DisposeBag()
    var noteInfo:NoteInfo!
    var oldupdatedAt:Date!
    private var model:NoteInfoViewModel!
    private var needDismiss = false
    private var isNoteUpdated:Bool = false
    var cellNodeTypes:[EditorCellNodeType] = [.content]
    
    private var isKeyboardShow = false
    var isNewCreated = false
    var cellHeight:CGFloat = -1
    
    var callbackNoteInfoEdited:((NoteInfo)->Void)?
    
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
    
    var contentCellIndex:Int {
        return self.cellNodeTypes.firstIndex(of: .content) ?? 0
    }
    
    var mediaCellIndex:Int {
        return self.cellNodeTypes.firstIndex(of: .media) ?? -1
    }
    
    
    private lazy var tableView = ASTableNode().then {
                $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 14, left: 0, bottom: bottomExtraSpace, right: 0)
        $0.view.allowsSelection = false
        $0.view.separatorStyle = .none
        $0.view.keyboardDismissMode = .none
        $0.view.keyboardDismissMode = .onDrag
    }
    
    
    lazy var bottomExtraSpace: CGFloat = 42.0 + 44
    let keyboardTop: CGFloat = 16
    
    var focusedTextView:UITextView? = nil
    
    override func viewDidLoad() {
        self.oldupdatedAt = self.noteInfo.updatedAt
        super.viewDidLoad()
        self.setupUI()
        self.registerNoteInfoEvent()
    }
    
    private func setupUI(){
        if self.noteInfo.files.count > 0 {
            self.cellNodeTypes.append(.media)
            self.cellHeight = self.calcMediaCollectionHeight()
        }
        
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
//            cell.textNode.textView.becomeFirstResponder()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.refreshTableNode(node: cell)
//            }
            
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
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appMovedToBackground() {
        self.saveInput(needDismiss: false)
    }
}

extension MDEditorViewController:UINavigationBarDelegate {
    
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

//MARK: 笔记更新
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
        case .fileUpdated(noteInfo: let noteInfo):
            self.noteInfo = noteInfo
            let newHeight = calcMediaCollectionHeight()
            let heightChanged = self.cellHeight != newHeight
            self.cellHeight = newHeight
            // 更新图片
            self.refreshMediaCell(heightChanged:heightChanged)
        }
    }
    
    func refreshMediaCell(heightChanged:Bool) {
        if mediaCellIndex == -1 {
            self.cellNodeTypes.append(.media)
            self.tableView.insertRows(at: [IndexPath(row: mediaCellIndex, section: 0)], with: .none)
            return
        }
        let row = IndexPath(row: mediaCellIndex, section: 0)
        guard let mediaCell = self.tableView.nodeForRow(at: row) as? NoteMediaCellNode else { return }
        if heightChanged {// 完整刷新
            self.tableView.reloadRowsWithoutAnim(at: [row])
            return
        }
        mediaCell.reload(newNoteFiles: self.noteInfo.files)
    }
    
    
    private func calcMediaCollectionHeight() -> CGFloat {
        let noteFiles = self.noteInfo.files
        
        var rowCount = noteFiles.count / Int(NoteMediaCellConstants.cellCount)
        if noteFiles.count % Int(NoteMediaCellConstants.cellCount) > 0 {
            rowCount += 1
        }
    
        let itemWidth = (UIScreen.main.bounds.width - MDEditorConfig.paddingH*2 - (NoteMediaCellConstants.cellCount - 1)*NoteMediaCellConstants.cellSpacing) / NoteMediaCellConstants.cellCount
        
        let cellHeight = itemWidth*CGFloat(rowCount) + (CGFloat(rowCount)-1) * NoteMediaCellConstants.cellSpacing
        return cellHeight
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
//            let backButtonImage =  UIImage(systemName: "camera",pointSize: 18)?.withTintColor(.toolbarTint).withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0))
//            let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
//            backButton.leftImage(image: backButtonImage!, renderMode: .alwaysOriginal)
//            let backBarButton = UIBarButtonItem(customView: backButton)
//            UIBarButtonItem(image: <#T##UIImage?#>, style: <#T##UIBarButtonItem.Style#>, target: <#T##Any?#>, action: <#T##Selector?#>)
            let cameraButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .plain, target: self, action: nil)
            
            let items = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "拍照或录视频", image: UIImage(systemName: "camera"), handler: { _ in
                    self.handlePickPhotos(sourceType: .camera)
                }),
                UIAction(title: "选取照片或视频", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in
                    self.handlePickPhotos(sourceType: .photoLibrary)
                }),
            ])
            cameraButtonItem.menu =  UIMenu(title: "", children: [items])
            
            
            navigationItem.leftBarButtonItems = [cameraButtonItem]
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
    
    
    @objc func tagIconTapped() {
    }
}

extension MDEditorViewController:NoteTitleCellNodeDelegate {
    
    func editableTextNodeDidBeginEditing(_ cellNode: NoteTitleCellNode) {
        self.focusedTextView = cellNode.textView
    }
    
    func textChanged(_ cellNode: NoteTitleCellNode) {
        self.refreshTableNode(node: cellNode)
    }
    
    func saveButtonTapped(_ cellNode: NoteTitleCellNode) {
        self.saveIconTapped()
    }
}

extension MDEditorViewController:NoteContentCellNodeDelegate {
    func pickPhotoButtonTapped(sourceType: UIImagePickerController.SourceType) {
        self.handlePickPhotos(sourceType: sourceType)
    }
    
    func editableTextNodeDidBeginEditing(_ cellNode: NoteContentCellNode) {
        self.focusedTextView = cellNode.textView
    }
    
    func textChanged(_ cellNode: NoteContentCellNode) {
        self.refreshTableNode(node: cellNode)
    }
    
    func saveButtonTapped(_ cellNode: NoteContentCellNode) {
        self.saveIconTapped()
    }
    
    
    @objc func saveIconTapped() {
        self.saveInput(needDismiss: true)
    }
    
    fileprivate func handlePickPhotos(sourceType:UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = sourceType
        
        self.present(pickerController, animated: true, completion: nil)
    }
}

//MARK: 图片选择
extension MDEditorViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //        self.pickerController(picker, didSelect: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        guard let image = image else { return }
        //保存图片
        self.model.saveImage(image: image)
    }
}


extension MDEditorViewController:ASTableDelegate {
    
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let cellNodeType = self.cellNodeTypes[indexPath.row]
        if cellHeight == -1 {
            cellHeight = self.calcMediaCollectionHeight()
        }
        switch cellNodeType {
        case .media:
            return ASSizeRange(min: .zero, max: .init(width: tableNode.frame.width, height: cellHeight))
        default:
            return ASSizeRangeUnconstrained
        }
    }
}

//MARK: NoteMediaCellNodeDelegate
extension MDEditorViewController:NoteMediaCellNodeDelegate {
    func imageTapped(_ cellNode: NoteMediaCellNode, index: Int) {
        let imageUrls = cellNode.noteFiles.map { ImageLocalUtil.sharedInstance.filePath(imageName: $0.id) }
        ImageViewerUtil.present(vc: self, imageUrls: imageUrls)
    }
    
    func imageChanged(_ cellNode: NoteMediaCellNode) {
        self.refreshTableNode(node: cellNode)
    }
}


//MARK: ASTableDataSource
extension MDEditorViewController:ASTableDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellNodeTypes.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNodeType = self.cellNodeTypes[indexPath.row]
        switch cellNodeType {
        case .title:
            let titleCellNode = NoteTitleCellNode(title: self.noteInfo.note.title)
            titleCellNode.delegate = self
            return titleCellNode
        case .content:
            let contentCellNode = NoteContentCellNode(title: self.noteInfo.note.content)
            contentCellNode.delegate = self
            return contentCellNode
        case .media:
            let contentCellNode = NoteMediaCellNode(noteFiles: self.noteInfo.files)
            contentCellNode.delegate = self
            return contentCellNode
        }
    }
    
    private func saveInput(needDismiss:Bool) {
        var title = ""
        if let titleCell = self.getNoteTitleCell()  {
            title = titleCell.textView.text
        }
        
        var content = ""
        if let contentCell = self.getNoteContentCellNode()  {
            content = contentCell.textView.text
        }
        let isUpdated = noteInfo.title != title  || noteInfo.content != content
        if isUpdated == false {
            if self.oldupdatedAt != self.noteInfo.note.updatedAt { //图片被更新了
                self.callbackNoteInfoEdited?(self.noteInfo)
            }
            if needDismiss {
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        self.needDismiss = needDismiss
        self.updateInputContent(title: title, content: content)
    }
    
    private func updateInputContent(title:String?,content:String?) {
        var note = self.noteInfo.note
        
        if let title = title {
            note.title = title
        }
        var tagsChanged = false
        var tagTitles:[String] = []
        if let content = content {
            note.content = content
            
            tagTitles = MDEditorViewController.extractTags(text: content)
            let noteTagTitles = self.noteInfo.tags
            tagsChanged =  !noteTagTitles.elementsEqual(tagTitles) { $0.title == $1 }
        }
        note.updatedAt = Date()
        
        if !tagsChanged { // 只更新内容
            self.model.updateNote(note)
            return
        }
        self.model.updateNoteAndTags(note: note, tagTitles: tagTitles)
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
                    self.scrollToCursorPositionIfBelowKeyboard(textView:focusedTextView)
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
