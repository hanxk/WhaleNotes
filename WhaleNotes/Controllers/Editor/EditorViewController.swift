//
//  NoteEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit
import ContextMenu
import RealmSwift
import MobileCoreServices
import TLPhotoPicker
import RxSwift
import MBProgressHUD
import DeepDiff

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    private var todoBlockCell: TodoBlockCell?
    
    
    private var attachmentsCell: AttachmentsBlockCell?
    
    
    var createMode: CreateMode?
    
    private var note: Note! {
        didSet {
            self.setupSectionsTypes(note: note)
            self.tableView.reloadData()
        }
    }
    // todoindex:(checkoruncheckindex:sectionindex)
    var todoRowIndexMap:[Int:(Int,Int)] = [:]
    
    var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private var todoGroupBlocksNotifiToken: NotificationToken?
    private var attachmentBlocksNotifiToken: NotificationToken?
    
    
    private var todoBlocksNotifiToken: [NotificationToken] = []
    
    private var noteNotificationToken: NotificationToken?
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TitleBlockCell.self, forCellReuseIdentifier: "title")
        $0.register(TextBlockCell.self, forCellReuseIdentifier:  "text")
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: "todo")
        $0.register(AttachmentsBlockCell.self, forCellReuseIdentifier: "attachments")
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomExtraSpace, right: 0)
        
        
        $0.delegate = self
        $0.dataSource = self
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        $0.dropDelegate = self
        
    }
    
    private lazy var bottombar: BottomBarView = BottomBarView().then {[weak self] in
        guard let self = self else { return }
        $0.moreButton.addTarget(self, action: #selector(self.handleMoreButtonTapped), for: .touchUpInside)
        $0.addButton.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
    
    deinit {
        noteNotificationToken?.invalidate()
        todoGroupBlocksNotifiToken?.invalidate()
    }
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    private var keyboardIsHide = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    @objc func rotated() {
        self.attachmentsCell?.handleScreenRotation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        tableView.endEditing(true)
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        
        self.view.addSubview(bottombar)
        bottombar.snp.makeConstraints { (make) in
            make.height.equalTo(bottombarHeight)
            make.width.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalTo(0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setFirstResponder()
        
    }
    
    private func setFirstResponder() {
        guard let createMode = createMode else { return }
        switch createMode {
        case .text: 
            textCell?.textView.becomeFirstResponder()
        case .todo:
            self.todoBlockCell?.textView.becomeFirstResponder()
        default:
            break
        }
    }
    
    @objc func handleMoreButtonTapped() {
        self.tableView.endEditing(true)
//        self.tableView.scrollToBottom()
    }
    
}

extension EditorViewController {
    @objc func handleAddButtonTapped() {
        let popMenuVC = PopBlocksViewController()
        popMenuVC.cellTapped = { [weak self] type in
            popMenuVC.dismiss(animated: true, completion: {
                self?.handleCreateModeMenu(type: type)
            })
        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: bottombar.addButton
        )
    }
    
    fileprivate func handleCreateModeMenu(type: MenuType) {
        self.tableView.resignFirstResponder()
        switch type {
        case .text:
            self.handleText()
        case .todo:
            self.handleTodoBlock()
            break
        case .image:
            let photoVC = TLPhotosPickerViewController()
            photoVC.delegate = self
            var configure = TLPhotosPickerConfigure()
            configure.allowedVideo = false
            configure.allowedLivePhotos = false
            configure.allowedVideoRecording = false
            photoVC.configure = configure
            self.present(photoVC, animated: true, completion: nil)
        case .camera:
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.image"]
            present(vc, animated: true)
        }
    }
    
    fileprivate func handleText() {
        if let textCell = textCell {
            textCell.textView.becomeFirstResponder()
            return
        }
        // 新增 textblock
        DBManager.sharedInstance.update {
            note.textBlock = Block.newTextBlock()
        }
    }
    
    fileprivate func handleTodoBlock() {
        // 新增 todo block
        DBManager.sharedInstance.update {
            note.todoBlocks.append(Block.newTodoGroupBlock())
        }
        
    }
}


// 数据处理
extension EditorViewController {
    
    fileprivate func setupData() {
        guard let createMode = self.createMode else {
            return
        }
        let note = self.generateNote(createMode: createMode)
        DBManager.sharedInstance.addNote(note)
        self.noteNotificationToken = note.observe { change in
            switch change {
            case .change(let properties):
                for property in properties {
                    self.handlePropertyChange(propertyChange: property)
                }
            case .error(let error):
                print("An error occurred: \(error)")
            case .deleted:
                print("The object was deleted.")
            }
        }
        self.note = note
    }
    fileprivate func handlePropertyChange(propertyChange: PropertyChange) {
        switch propertyChange.name {
        case  "textBlock":
            self.handleTextBlockUpdate(change: propertyChange)
        case "attachBlocks":
            self.handleAttachBlockUpdate(change:propertyChange)
        default:
            break
        }
    }
    
    fileprivate func handleTextBlockUpdate(change: PropertyChange) {
        if let textBlock = (change.newValue as? Block), change.oldValue == nil { // 新增 text
            let sectionIndex = 1
            self.sections.insert(SectionType.text(textBlock: textBlock), at: sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .automatic)
            }) { _ in
                self.textCell?.textView.becomeFirstResponder()
            }
        }
    }
    
    
    fileprivate func handleAttachBlockUpdate(change: PropertyChange) {
        let attachBlocks = change.newValue as! List<Block>
        if attachmentsCell == nil && attachBlocks.count > 0 { // 新增
            let sectionIndex = self.sections.count
            self.sections.append(SectionType.attachments(attachmentBlocks: Array(attachBlocks)))
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .automatic)
            }) { _ in
            }
        }
    }
    
    
    fileprivate func generateNote(createMode: CreateMode) -> Note {
        let note: Note = Note()
        note.titleBlock = Block.newTitleBlock()
        switch createMode {
        case .text:
            note.textBlock = Block.newTextBlock()
            break
        case .todo:
            note.todoBlocks.append(Block.newTodoGroupBlock())
            break
        case .attachment(let blocks):
            note.attachBlocks.append(objectsIn: blocks)
            break
        }
        return note
    }
    
    fileprivate func setupSectionsTypes(note: Note) {
        if let titleBlock = note.titleBlock {
            self.sections.append(SectionType.title(titleBlock: titleBlock))
        }
        if let textBlock = note.textBlock {
            self.sections.append(SectionType.text(textBlock: textBlock))
        }
        
        self.todoGroupBlocksNotifiToken =  self.setupTodoSections(todoBlocks: note.todoBlocks)
        
        if !note.attachBlocks.isEmpty {
            self.sections.append(SectionType.attachments(attachmentBlocks: Array(note.attachBlocks)))
        }
    }
    
    fileprivate func setupTodoSections(todoBlocks: List<Block>) -> NotificationToken {
        let notificationToken = todoBlocks.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: _):
                if deletionIndices.count > 0 || insertionIndices.count > 0 {
                    self.handleTodoSectionUpdate(insertionIndices: insertionIndices, deletionIndices: deletionIndices)
                }
                break
            case .error(let error):
                print(error)
            case .initial:
                self.observeSectionTodos()
                self.tableView.reloadData()
            }
            
        }
        return notificationToken
    }
    
    fileprivate func handleTodoSectionUpdate(insertionIndices: [Int],deletionIndices:[Int] ) {
        
        let firstSectionIndex = self.firstTodoSectionIndex
        
        // 更新数据源
        updateObserver(insertionIndices:insertionIndices)
        
        tableView.performBatchUpdates({
            tableView.deleteSections(IndexSet(deletionIndices.map{ $0 + firstSectionIndex }), with: .automatic)
            tableView.insertSections(IndexSet(insertionIndices.map{ $0 + firstSectionIndex }), with: .automatic)
        }) { _ in
            if insertionIndices.count > 0 {
                if let lastTodoSection = insertionIndices.max() {
                    self.tryGetFocus(sectionIndex:(lastTodoSection + firstSectionIndex))
                }
            }
        }
    }
    
    fileprivate func updateObserver(insertionIndices:[Int]) {
        let firstSectionIndex = self.firstTodoSectionIndex
        insertionIndices.forEach { sectionIndex in
            let sIndex = sectionIndex + firstSectionIndex
            let todoGroupBlocks = self.note.todoBlocks
            let todoGroupBlock = todoGroupBlocks[sectionIndex]
            self.sections.insert( SectionType.todo(todoGroupBlock: todoGroupBlock), at: sIndex)
            let notificationToken =  todoGroupBlock.blocks.observe { changes in
                self.handleTodoChanges(todoGroupBlock:todoGroupBlock, changes: changes)
            }
            self.todoBlocksNotifiToken.insert(notificationToken, at: sectionIndex)
        }
    }
    
    fileprivate func observeSectionTodos() {
        
        let todoGroupBlocks = self.note.todoBlocks
        let sectionIndex = self.firstTodoSectionIndex
        // 生成section
        self.sections.insert(contentsOf: todoGroupBlocks.map { SectionType.todo(todoGroupBlock: $0)}, at: sectionIndex)
        
        self.todoBlocksNotifiToken = todoGroupBlocks.map { todoGroupBlock in
            todoGroupBlock.blocks.observe { changes in
                self.handleTodoChanges(todoGroupBlock:todoGroupBlock, changes: changes)
            }
        }
    }
    
    fileprivate func handleTodoChanges(todoGroupBlock: Block,changes: RealmCollectionChange<List<Block>>) {
        switch changes {
        case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, _):
            guard let sectionIndex = self.note.todoBlocks.index(of: todoGroupBlock)  else { return }
            let sIndex = sectionIndex + self.firstTodoSectionIndex
            tableView.performBatchUpdates({
                tableView.deleteRows(at: deletionIndices.map{ IndexPath(row: $0, section: sIndex)}, with: .automatic)
                tableView.insertRows(at: insertionIndices.map{ IndexPath(row: $0, section: sIndex)}, with: .automatic)
            }) { _ in
                if !insertionIndices.isEmpty { // 弹出键盘
                    self.tryGetFocus(sectionIndex: sIndex)
                }
            }
            break
        case .error(let error):
            print(error)
        case .initial(let type):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tryGetFocus(sectionIndex: self.firstTodoSectionIndex)
            }
            print(type)
        }
    }
    
}

// 数据处理-todo
extension EditorViewController {
    
    //    func getFirstTodoBlockSectionIndex() -> Int {
    //        var index = 0
    //        self.sections.forEach {
    //            switch $0 {
    //            case .title:
    //                index += 1
    //                break
    //            case .text:
    //                index += 1
    //                break
    //            default:
    //                break
    //            }
    //        }
    //        return index
    //    }
    
    var firstTodoSectionIndex: Int {
        var index = 0
        if titleCell != nil {
            index += 1
        }
        
        if textCell != nil {
            index += 1
        }
        
        return index
    }
    
    
    private func getUncheckedAndCheckedTodos(todoBlocks: List<Block>,unCheckedSectionIndex:Int,checkedSectionIndex:Int) -> ([Block],[Block]) {
        
        var unCheckedBlocks:[Block] = []
        var checkedBlocks:[Block] = []
        
        self.todoRowIndexMap.removeAll()
        
        for (index, block) in Array(todoBlocks).enumerated() {
            if block.isChecked {
                self.todoRowIndexMap[index] = (checkedBlocks.count,checkedSectionIndex)
                checkedBlocks.append(block)
            }else {
                self.todoRowIndexMap[index] = (unCheckedBlocks.count,unCheckedSectionIndex)
                unCheckedBlocks.append(block)
            }
        }
        return (unCheckedBlocks,checkedBlocks)
    }
    
    
    private func tryGetFocus(sectionIndex: Int) {
        if let  emptyBlockIndex = self.sections[sectionIndex].getTodoGroupBlock()?.blocks.firstIndex(where: { $0.text.isEmpty }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: emptyBlockIndex, section: sectionIndex)) as? TodoBlockCell {
                cell.textView.becomeFirstResponder()
            }
        }
    }
    
    private func insertSectionReload(sectionIndex: Int) {
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .bottom)
        }, completion: nil)
    }
    
    private func deleteSectionReload(sectionIndex: Int) {
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .top)
        }, completion: nil)
    }
    
}

extension EditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo(let todoGroupBlock):
            if todoGroupBlock.isExpand {
                return todoGroupBlock.blocks.count
            }
            return 0
        default:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: sectionObj.identifier, for: indexPath)
        switch sectionObj {
        case .title(let titleBlock):
            let titleCell = (cell as! TitleBlockCell).then {
                $0.titleBlock = titleBlock
                $0.enterkeyTapped { [weak self] _ in
                    self?.textCell?.textView.becomeFirstResponder()
                }
            }
            self.titleCell = titleCell
            break
        case .text(let textBlock):
            let textCell = cell as! TextBlockCell
            textCell.textBlock = textBlock
            textCell.textChanged {[weak tableView] newText in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            self.textCell = textCell
            break
        case .todo(let todoGroupBlock):
            let todoCell = cell as! TodoBlockCell
            todoCell.todoGroupBlock = todoGroupBlock
            todoCell.todoBlock = todoGroupBlock.blocks[indexPath.row]
            todoCell.textChanged =  {[weak tableView] textView in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            todoCell.textShouldBeginChange = {[weak self] in
                self?.todoBlockCell = todoCell
            }
            todoCell.textViewShouldEndEditing = {[weak self] in
                self?.todoBlockCell = nil
            }
            break
        case .attachments:
            let imagesCell = cell as! AttachmentsBlockCell
            imagesCell.heightChanged = { [weak tableView]  in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            imagesCell.note = self.note
            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
    
    fileprivate func handleTextViewEnterKey(textView: UITextView){
        let tableView = self.tableView
        if let cursorPosition = textView.selectedTextRange?.start {
            let caretPositionRect = textView.caretRect(for: cursorPosition)
            
            let inWindowRect = textView.convert(caretPositionRect, to: nil)
            let visibleHeight = UIScreen.main.bounds.height - (self.keyboardHeight+self.bottombarHeight)
            
            let cursorY = inWindowRect.origin.y +  caretPositionRect.height
            
            Logger.info("cursorY", cursorY)
            Logger.info("visibleHeight", visibleHeight)
            if cursorY > visibleHeight { // 光标隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let newOffsetY =  tableView.contentOffset.y +  (cursorY - self.keyboardHeight2)
                    Logger.info("tableView.contentOffset.y", tableView.contentOffset.y)
                    Logger.info("newOffsetYy", newOffsetY)
                    // your code here
                    tableView.contentOffset.y = newOffsetY
//                    tableView.scrollRectToVisible(CGRect.init(x: 0, y: cursorY, width: 0, height: 0), animated: false)
//                    tableView.scroll
//                    tableView.scrollToBottom()
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo(let todoGroupBlock):
            let todoHeaderView = TodoHeaderView()
            todoHeaderView.note = self.note
            todoHeaderView.todoGroupBlock = todoGroupBlock
            //            todoHeaderView.backgroundColor = .brown
            todoHeaderView.addButtonTapped = {
                DBManager.sharedInstance.update(withoutNotifying: self.todoBlocksNotifiToken) {
                    todoGroupBlock.isExpand = !todoGroupBlock.isExpand
                }
                if let sectionIndex = self.note.todoBlocks.index(of: todoGroupBlock) {
                    self.tableView.reloadSections(IndexSet(integer: sectionIndex+self.firstTodoSectionIndex), with: .automatic)
                }
            }
            return todoHeaderView
        default:
            return nil
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .attachments(_):
            return attachmentsCell?.totalHeight ?? 0
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo:
            return 34
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo:
            return true
        default:
            return false
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard  let todoGroupBlock = self.sections[sourceIndexPath.section].getTodoGroupBlock() else { return }
        
        let blocks = todoGroupBlock.blocks
        
        let fromIndex = sourceIndexPath.row
        let toIndex = destinationIndexPath.row
        DBManager.sharedInstance.update(withoutNotifying: [self.todoGroupBlocksNotifiToken!]) {
            blocks.move(from: fromIndex, to: toIndex)
        }
        
        // 交换顺序
        let todoBlock = blocks[fromIndex]
        blocks.remove(at: fromIndex)
        blocks.insert(todoBlock, at: toIndex)
        
        //        self.sections[sourceIndexPath.section] = SectionType.todo(todoGroupBlock: blocks)
        //        self.sections[sourceIndexPath.section] =  SectionType.todo(todoBlocks: newUnCheckedTodos, mode: .unchecked)
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        if destSection < sourceSection {
            return IndexPath(row: 0, section: sourceSection)
        } else if destSection > sourceSection {
            return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
        }
        return proposedDestinationIndexPath
    }
}

// drag and drop
extension EditorViewController: UITableViewDragDelegate, UITableViewDropDelegate  {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}

// 键盘
extension EditorViewController {
    
    @objc func handleKeyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            let rect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]  as! NSValue).cgRectValue
            keyboardIsHide = false
            keyboardHeight = rect.height
            keyboardHeight2 =  keyboardHeight + bottombarHeight
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            self.bottombar.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset( -(rect.height - view.safeAreaInsets.bottom))
            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
            
            var contentInset = self.tableView.contentInset
            contentInset.bottom = rect.height + bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
            
        }
    }
    
    @objc func handleKeyboardHideNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            guard let view = self.view else{
                return
            }
            if keyboardIsHide {
                return
            }
            keyboardHeight = 0
            keyboardIsHide = true
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            self.bottombar.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(0)
            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
            var contentInset = self.tableView.contentInset
            contentInset.bottom = bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
        }
    }
}

// 相册
extension EditorViewController: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    func handlePicker(images: [TLPHAsset]) {
        self.showHud()
        Observable<[TLPHAsset]>.just(images)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(images)  -> [Block] in
                var imageBlocks:[Block] = []
                images.forEach {
                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
                        let imageName =  $0.uuidName
                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                        if success {
                            imageBlocks.append(Block.newImageBlock(imageUrl: imageName))
                        }
                    }
                }
                return imageBlocks
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    DBManager.sharedInstance.update {
                        self.note.attachBlocks.append(objectsIn: blocks)
                    }
                }
        }
        .disposed(by: disposeBag)
    }
}

// camera 选择
extension EditorViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {  return}
        self.handlePicker(image: image)
    }
    
    func handlePicker(image: UIImage) {
        self.showHud()
        Observable<UIImage>.just(image)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(image)  -> [Block] in
                let imageName = UUID().uuidString+".png"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        return [Block.newImageBlock(imageUrl: imageName)]
                    }
                }
                return []
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    DBManager.sharedInstance.update {
                        self.note.attachBlocks.append(objectsIn: blocks)
                    }
                }
        }
        .disposed(by: disposeBag)
    }
    
    
}



enum SectionType {
    case title(titleBlock: Block)
    case text(textBlock: Block)
    case todo(todoGroupBlock:Block)
    case attachments(attachmentBlocks: [Block])
    
    var identifier: String {
        switch self {
        case .title:
            return "title"
        case .text:
            return "text"
        case .todo:
            return "todo"
        case .attachments:
            return "attachments"
        }
    }
    
    func getTodoGroupBlock() -> Block? {
        switch self {
        case .todo(let todoGroupBlock):
            return todoGroupBlock
        default:
            return nil
        }
    }
}

enum TodoMode {
    case unchecked
    case checked
}


enum CreateMode {
    case text
    case todo
    case attachment(blocks:[Block])
}
