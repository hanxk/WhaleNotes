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

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    static let cellSpace: CGFloat = 2
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    private var titleCell:TitleBlockCell?
    private var contentCell: TextBlockCell?
    private var todoBlockCell: TodoBlockCell?
    
    private var imagesCell: ImageBlockCell?
    
    
    private var note: Note! {
        didSet {
            self.setupSectionsTypes(note: note)
            self.tableView.reloadData()
        }
    }
    
    var createMode: CreateMode?
    
    var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private var todoUnCheckedListNotifiToken: NotificationToken?
    private var todoCheckedListNotifiToken: NotificationToken?
    
    private var noteNotificationToken: NotificationToken?
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TitleBlockCell.self, forCellReuseIdentifier: "title")
        $0.register(TextBlockCell.self, forCellReuseIdentifier:  "text")
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: "todo")
        $0.register(ImageBlockCell.self, forCellReuseIdentifier: "image")
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
        todoUnCheckedListNotifiToken?.invalidate()
        todoCheckedListNotifiToken?.invalidate()
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
        self.imagesCell?.collectionView.reloadData()
        self.imagesCell?.collectionView.collectionViewLayout.invalidateLayout()
        
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
            contentCell?.textView.becomeFirstResponder()
        case .todo: 
            self.todoBlockCell?.textView.becomeFirstResponder()
        default:
            break
        }
    }
    
    @objc func handleMoreButtonTapped() {
        self.tableView.endEditing(true)
    }
    
    
    @objc func handleAddButtonTapped() {
        let popMenuVC = PopBlocksViewController()
        //        popMenuVC.cellTapped = { [weak self] createMode in
        //
        //        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: bottombar.addButton
        )
    }
    
}
// 数据处理
extension EditorViewController {
    
    
    
    func generateNote(createMode: CreateMode) -> Note {
        let note: Note = Note()
        note.blocks.append(Block.newTitleBlock())
        switch createMode {
        case .text:
            note.blocks.append(Block.newTextBlock())
            break
        case .todo:
            note.blocks.append(Block.newTodoBlock(note: note))
            break
        case .image(let images):
            note.blocks.append(Block.newImageBlock(images: generateImages(images: images)))
            break
        }
        return note
    }
    
    private func setupData() {
        guard let createMode = self.createMode else {
            return
        }
        var workScheduler: ImmediateSchedulerType = MainScheduler.instance
        if case .image = createMode {  // 耗时任务在子线程中
            workScheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)
            self.showHud()
        }
        Observable<CreateMode>.just(createMode)
            .observeOn(workScheduler)
            .map({(createMode)  -> Note in
                return self.generateNote(createMode: createMode)
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                if let note = $0.element {
                    DBManager.sharedInstance.addNote(note)
                    self.note = note
                }
                self.hideHUD()
        }
        .disposed(by: disposeBag)
        
    }
    
    private func generateImages(images: [TLPHAsset]) -> [Image] {
        var newImages: [Image] = []
        for imageAsset in images {
            let image = Image()
            guard let  fullResolutionImage = imageAsset.fullResolutionImage,
                 let originalFileName = imageAsset.originalFileName else { continue }
            let nameArray = originalFileName.split(separator: ".")
            let imageExtension = nameArray.count > 0 ? String(nameArray[nameArray.count-1]).lowercased() : "png"
            image.extention = imageExtension
            let isSuccess =  ImageUtil.sharedInstance.saveImage(key: image.id,imageExtension: imageExtension, image: fullResolutionImage)
            if isSuccess {
                newImages.append(image)
            }
        }
        return newImages
    }
    
    
    private func setupSectionsTypes(note: Note) {
        for block in note.blocks {
            switch block.blockType {
            case .title:
                self.sections.append(SectionType.title(titleBlock: block))
            case .text:
                self.sections.append(SectionType.text(textBlock: block))
            case .todo:
                self.setupTodoSections(todoBlock: block)
            case .image:
                self.sections.append(SectionType.image(imageBlock: block))
            }
        }
    }
    
}

// 数据处理-todo
extension EditorViewController {
    
    
    private func setupTodoSections(todoBlock: Block) {
        self.todoUnCheckedListNotifiToken = observeTodoList(todoBlock: todoBlock, todoMode: .unchecked)
        self.todoCheckedListNotifiToken = observeTodoList(todoBlock: todoBlock, todoMode: .checked)
    }
    
    private func observeTodoList(todoBlock: Block,  todoMode: TodoMode) -> NotificationToken{
        switch todoMode {
        case .unchecked:
            return self.observerTodoUnCheckedList(todoBlock: todoBlock)
        case .checked:
            return self.observerTodoCheckedList(todoBlock: todoBlock)
        }
    }
    private func observerTodoUnCheckedList(todoBlock: Block) -> NotificationToken {
        let todoResults = todoBlock.todos.filter("isChecked = false")
        let notificationToken = todoResults.observe { [weak self] changes in
            guard let self = self else { return }
            
            if let sectionIndex =  self.getTodoSectionIndex(todoMode: .unchecked) { // 更新 section data
                self.sections[sectionIndex] =  SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults), mode: .unchecked)
                self.handleTodoUpdate(changes: changes,section: sectionIndex,insertNeedShowKeyboard: true)
                return
            }
            guard let todoSectionIndex = self.note.blocks.firstIndex(where: { $0.blockType == .todo }) else { return }
            let todoSection = SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults), mode: .unchecked)
            self.sections.insert(todoSection, at: todoSectionIndex)
            self.insertSectionReload(sectionIndex: todoSectionIndex)
        }
        return notificationToken
    }
    
    
    private func observerTodoCheckedList(todoBlock: Block) -> NotificationToken {
        let todoResults = todoBlock.todos.filter("isChecked = true")
        let notificationToken = todoResults.observe { [weak self] changes in
            guard let self = self else { return }
            if let sectionIndex =  self.getTodoSectionIndex(todoMode: .checked) { // 更新 section data
                if todoResults.count > 0 {
                    self.sections[sectionIndex] =  SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults), mode: .checked)
                    if self.isTodoExpand {
                        self.handleTodoUpdate(changes: changes,section: sectionIndex)
                    }
                }else {
                    self.sections.remove(at: sectionIndex)
                    self.deleteSectionReload(sectionIndex: sectionIndex)
                }
                return
            }
            if todoResults.count == 0 {
                return
            }
            guard let unCheckedTodoSectionIndex = self.note.blocks.firstIndex(where: { $0.blockType == .todo }) else { return }
            let checkedTodoSectionIndex  = unCheckedTodoSectionIndex + 1
            let todoSection = SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults), mode: .checked)
            self.sections.insert(todoSection, at: checkedTodoSectionIndex)
            self.insertSectionReload(sectionIndex: checkedTodoSectionIndex)
            
        }
        return notificationToken
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
    
    
    private func handleTodoUpdate(changes: RealmCollectionChange<Results<Todo>>,section: Int,insertNeedShowKeyboard: Bool = false) {
        
        let tableView  = self.tableView
        switch changes {
        case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: let modIndices):
            print("Objects deleted from indices: \(deletionIndices)")
            print("Objects inserted to indices: \(insertionIndices)")
            print("Objects modified at indices: \(modIndices)")
            tableView.beginUpdates()
            tableView.deleteRows(at: deletionIndices.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            tableView.insertRows(at: insertionIndices.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            //                             tableView.reloadRows(at: modIndices.map({ IndexPath(row: $0, section: section) }),
            //                                                  with: .automatic)
            
            tableView.endUpdates()
            if insertionIndices.count > 0 && insertNeedShowKeyboard {
                let indices = insertionIndices[insertionIndices.count-1]
                let blockCell = self.tableView.cellForRow(at: IndexPath(row: indices, section: section)) as! TodoBlockCell
                blockCell.textView.becomeFirstResponder()
            }
        case .error(let error):
            print(error)
        case .initial(let type):
            tableView.reloadData()
            print(type)
        }
    }
    
    
    private func getTodoSectionIndex(todoMode: TodoMode) -> Int?  {
        return  self.sections.firstIndex {
            switch $0 {
            case .todo(_, _, let mode):
                return mode == todoMode
            default:
                return false
            }
        }
    }
    
}

extension EditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo(_, let todos,let mode):
            switch mode {
            case .unchecked:
                return todos.count
            case .checked:
                return self.isTodoExpand ? todos.count : 0
            }
            
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
                    self?.contentCell?.textView.becomeFirstResponder()
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
                let textView = textCell.textView
                if let cursorPosition = textView.selectedTextRange?.start {
                    let caretPositionRect = textView.caretRect(for: cursorPosition)
                    textView.scrollRectToVisible(caretPositionRect, animated: false)
                    if caretPositionRect.origin.y < 0 { // 按回车键
                        tableView?.scrollToBottom()
                    }
                }
            }
            self.contentCell = textCell
            break
        case .todo(let todoblock,let todos,_):
            let todoCell = cell as! TodoBlockCell
            self.setupTodoCell(todoCell: todoCell, todos: todos, todoBlock: todoblock, indexPath: indexPath)
            break
        case .image(imageBlock: let imageBlock):
            let imagesCell = cell as! ImageBlockCell
            imagesCell.imageBlock = imageBlock
            self.imagesCell = imagesCell
            break
        }
        return cell
    }
    private func setupTodoCell(todoCell: TodoBlockCell,todos: [Todo],todoBlock: Block,indexPath: IndexPath) {
        let todo = todos[indexPath.row]
        todoCell.todo = todo
        todoCell.todoBlock = todoBlock
        todoCell.textChanged =  {[weak tableView] textView in
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    tableView?.beginUpdates()
                    tableView?.endUpdates()
                }
            }
        }
        self.todoBlockCell = todoCell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo(let todoBlock, _, let mode):
            switch mode {
            case .unchecked:
                let todoHeaderView = TodoHeaderView()
                todoHeaderView.todoBlock = todoBlock
                return todoHeaderView
            case .checked:
                let todoCompleteHeaderView = TodoCompleteHeaderView()
                todoCompleteHeaderView.isExpand = self.isTodoExpand
                todoCompleteHeaderView.todoBlock = todoBlock
                todoCompleteHeaderView.expandStateChanged = {[weak self] isExpand in
                    // 刷新 complete section
                    guard let self = self else { return }
                    let sectionIndex = self.sections.firstIndex { sectionType -> Bool in
                        switch sectionType {
                        case .todo(_, _, let mode):
                            return mode == .checked
                        default:
                            return false
                        }
                    }
                    self.isTodoExpand = isExpand
                    if sectionIndex != nil {
                        self.tableView.reloadSections(IndexSet(integer: sectionIndex!), with: .automatic)
                    }
                }
                return todoCompleteHeaderView
            }
        default:
            return nil
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let block = note.blocks[indexPath.section]
        if block.blockType == .image {
            // 计算 collectionview 高度
            return ImageBlockCell.calculateCellHeight(imageBlock: block)
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo(_, _,_):
            return 44
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo(_, _, let mode):
            switch mode {
            case .unchecked:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard let unCheckedTodos = self.sections[sourceIndexPath.section].getTodos(todoMode: .unchecked) else { return }
        guard let todoBlock = self.note.todoBlock else { return }
        
        let allTodos = todoBlock.todos
        
        guard let from = allTodos.index(of: unCheckedTodos[sourceIndexPath.row]),
            let to = allTodos.index(of: unCheckedTodos[destinationIndexPath.row]) else { return }
        DBManager.sharedInstance.update(withoutNotifying: [self.todoUnCheckedListNotifiToken!]) {
            allTodos.move(from: from, to: to)
        }
        
        // 交换顺序
        var newUnCheckedTodos = unCheckedTodos
        let todo = newUnCheckedTodos.remove(at: sourceIndexPath.row)
        newUnCheckedTodos.insert(todo, at: destinationIndexPath.row)
        
        self.sections[sourceIndexPath.section] =  SectionType.todo(todoBlock: todoBlock, todos: Array(newUnCheckedTodos), mode: .unchecked)
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
    
    private func getDragItem(todo: Todo) -> [UIDragItem] {
        
        guard let data = todo.id.data(using: .utf8) else { return [] }
        
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)
        
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
        //        print(dragIndexPath)
        //        coordinator.session.loadObjects(ofClass: NSString.self) { items in
        //            print(items)
        //            guard let destinationIndexPath: IndexPath = coordinator.destinationIndexPath else { return }
        //            guard let dragIndexPath: IndexPath = self.dragIndexPath else { return }
        //
        //            guard let unChckedTodos = self.sections[dragIndexPath.section].getTodos(todoMode: .unchecked) else { return }
        //            let allTodoList = self.note.blocks[dragIndexPath.section].todos
        //
        //            guard let dragDataIndex = allTodoList.firstIndex(where: { $0.id == unChckedTodos[dragIndexPath.row].id }) else { return }
        //            guard let desDataIndex = allTodoList.firstIndex(where: { $0.id == unChckedTodos[destinationIndexPath.row].id }) else { return }
        //            Logger.info("dragDataIndex ",dragDataIndex)
        //            Logger.info("desDataIndex ",desDataIndex)
        //            allTodoList.move(from: dragDataIndex, to: desDataIndex)
        //            self.tableView.reloadData()
        //        }
    }
}

// 键盘
extension EditorViewController {
    
    @objc func handleKeyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            let rect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]  as! NSValue).cgRectValue
            keyboardIsHide = false
            keyboardHeight = rect.height
            keyboardHeight2 += bottombarHeight
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


enum SectionType {
    case title(titleBlock: Block)
    case text(textBlock: Block)
    case todo(todoBlock: Block, todos: [Todo],mode: TodoMode)
    case image(imageBlock: Block)
    
    var identifier: String {
        switch self {
        case .title:
            return "title"
        case .text:
            return "text"
        case .todo:
            return "todo"
        case .image:
            return "image"
        }
    }
    
    
    func getTodos(todoMode: TodoMode) -> [Todo]? {
        switch self {
        case .todo(_, let todos, let mode):
            if mode == todoMode {
                return todos
            }
            return nil
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
    case image(images: [TLPHAsset])
}
