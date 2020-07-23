//
//  SideMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

enum SideMenuCellContants {
    static let iconWidth:CGFloat = 34
    static let cellPadding = 20
    static let highlightColor =  UIColor(hexString: "#EFEFEF")
}

protocol SideMenuViewControllerDelegate: AnyObject {
    func sideMenuItemSelected(menuItemType:SideMenuItem)
}

enum SideMenuItem:Equatable {
    
    case system(menuInfo:MenuSystemItem)
    case board(board:BlockInfo)
    
    static func == (lhs: SideMenuItem, rhs: SideMenuItem) -> Bool {
        switch (lhs,rhs)  {
        case (.system(let lmenu),.system(let rmenu) ):
            return  lmenu == rmenu
        case (.system,.board):
            return false
        case (.board(let board),.board(let board2)):
            return board.id == board2.id
        case (.board,.system):
            return false
        }
    }
}

enum SelectedMenuItem {
    case trash
    case board(groupId:String,boardId:String)
    
    
    var boardId:String {
        switch self {
        case .trash:
            return ""
        case .board(_,let boardId):
            return boardId
        }
    }
}

class SideMenuViewController: UIViewController {
    
    private var menuSectionTypes:[MenuSectionType] = []
    
    var space:Space!
    var spaceInfo:SpaceInfo!
    
    var boardGroupBlock:BlockInfo {
        get {
            return spaceInfo.boardGroupBlock
        }
        set {
            spaceInfo.boardGroupBlock = newValue
        }
    }
    
    var categoriesInfos:[BlockInfo] {
        get {
            return spaceInfo.categoryGroupBlock.contentBlocks
        }
        set {
            spaceInfo.categoryGroupBlock.contentBlocks = newValue
        }
    }
    
    
//    var blocksMap:[String:Block] = [:]
//    var blockInfos:[BlockInfo] = []
    
    private let disposeBag = DisposeBag()
    weak var delegate:SideMenuViewControllerDelegate? = nil {
        didSet {
            self.loadBoards()
        }
    }
    
    var sectionSpecial = -1
    
    private var deletedBoard: BlockInfo?
    private var updatedBoard: BlockInfo?
    
    //    private var selectedMenuItem:SideMenuItem! {
    //
    //        didSet {
    //            if oldValue != selectedMenuItem {
    //                delegate?.sideMenuItemSelected(menuItemType: selectedMenuItem)
    //                self.dismiss(animated: true, completion: nil)
    //            }
    //        }
    //
    //    }
    
    private var selectedId:String = ""
    private var selectedItem:SelectedMenuItem!
    
    //    var selectedMenuItem:SideMenuItem {
    //        return switch self.selectedItem {
    //        case .trash:
    //            return SideMenuItem.system(menuInfo: self.systemMenuItems[1])
    //        case .board(_,let boardId):
    //            if boardId == self.space.
    //            return boardId
    //        }
    //    }
    
    private lazy var bottomView:SideMenuBottomView = SideMenuBottomView().then {
        
        $0.callbackNewBlock = { sender in
            let items = [
                ContextMenuItem(label: "添加便签板", icon: "plus.rectangle",tag: 1),
                ContextMenuItem(label: "添加分类", icon: "folder.badge.plus",tag:2)
            ]
            ContextMenuViewController.show(sourceView:sender, sourceVC: self, items: items) { [weak self] menuItem, vc  in
                vc.dismiss(animated: true, completion: nil)
                guard let self = self,let flag = menuItem.tag as? Int else { return}
                if flag == 1 {
                    self.openCreateBoardVC(parent: self.boardGroupBlock)
                }else {
                    self.showCategoryInputAlert()
                }
            }
            
        }
        
    }
    
    private func openCreateBoardVC(parent:BlockInfo) {
        let vc = CreateBoardViewController()
        vc.callbackPositive = {emoji,title in
            self.createBoard(emoji: emoji, title: title, parent: parent)
        }
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    private func showCategoryInputAlert(toggleBlock:BlockInfo? = nil) {
        let ac = UIAlertController(title: toggleBlock == nil ? "添加分类" : "编辑分类", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].placeholder = "输入分类名称"
        ac.textFields![0].text = toggleBlock == nil ? "" :  toggleBlock!.blockToggleProperties!.title
        
        let submitAction = UIAlertAction(title: "确定", style: .default) { [unowned ac] _ in
            let title = ac.textFields![0].text!.trimmingCharacters(in: .whitespaces)
            if title.isEmpty { return }
            if let toggleBlock = toggleBlock {
                var newToggleBlock = toggleBlock
                newToggleBlock.block.updatedAt = Date()
                newToggleBlock.blockToggleProperties?.title = title
                self.updateToggleBlockProperties(toggleBlock: newToggleBlock)
            }else {
                self.createToggleBlock(title: title)
            }
        }
        ac.addAction(submitAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    
    
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.separatorColor = .clear
        $0.register(MenuSystemCell.self, forCellReuseIdentifier:CellReuseIdentifier.system.rawValue)
        $0.register(MenuBoardCell.self, forCellReuseIdentifier:CellReuseIdentifier.board.rawValue)
        $0.register(MenuCategoryCell.self, forCellReuseIdentifier:CellReuseIdentifier.category.rawValue)
        
        $0.separatorColor = .clear
        
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        $0.delegate = self
        $0.dataSource = self
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        
        $0.showsVerticalScrollIndicator = false
        
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        
        $0.dragInteractionEnabled = true
    }
    private var systemMenuItems:[MenuSystemItem]  =  []
    //    private var boards:[Board] = []
    //    private var mapCategoryIdAnIndex:[String:Int]  = [:]
    //    private var boardCategories:[BoardCategoryInfo] = [] {
    //        didSet {
    //            self.mapCategoryIdAnIndex.removeAll()
    //            for (index,boardCategoryInfo) in boardCategories.enumerated() {
    //                mapCategoryIdAnIndex[boardCategoryInfo.category.id] = index
    //            }
    //        }
    //    }
    private let sectionCategoryBeginIndex = 2
    
    private lazy var cellSelectedBackgroundView = SideMenuViewController.generateCellSelectedView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.tableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let deletedBoard = deletedBoard {
            self.deletedBoard = nil
            self.handleDeleteBoard(board: deletedBoard)
        }else if let updatedBoard = updatedBoard {
            self.updatedBoard = nil
            self.handleUpdateBoard(board: updatedBoard)
        }
    }
    
    private func setupUI() {
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        
        self.view.addSubview(bottomView)
        bottomView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(44)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tableView.backgroundColor = .sidemenuBg
        
    }
    
    private func loadBoards() {
        SpaceRepo.shared.getSpace()
            .subscribe {
                self.setupData(spaceInfo: $0)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    
    private func setupData(spaceInfo:SpaceInfo) {
        self.spaceInfo = spaceInfo
        let systemMenuItems =  [
            MenuSystemItem.board(board: spaceInfo.collectBoard),
            MenuSystemItem.trash(icon: "trash", title: "废纸篓")
        ]
        
        selectedId = spaceInfo.collectBoard.id
        
        menuSectionTypes.removeAll()
        
        self.systemMenuItems = systemMenuItems
        menuSectionTypes.append(MenuSectionType.system(items:systemMenuItems))
        
        menuSectionTypes.append(MenuSectionType.boards(groupId: boardGroupBlock.id))
        for blockInfo in categoriesInfos {
            menuSectionTypes.append(MenuSectionType.boards(groupId: blockInfo.id))
        }
        self.selectedItem = .board(groupId: "", boardId: spaceInfo.collectBoard.id)
        self.notifyMenuSelected(selectedIndex: IndexPath(row: 0, section: 0))
    }
    
}


//MARK: board 分类
extension SideMenuViewController {
    
    func createToggleBlock(title:String) {
        
        let toggleBlock = Block.newToggleBlock(parent: self.spaceInfo.categoryGroupBlock.id, parentTable: .block, properties: BlockToggleProperty(title: title))
        
        let position = self.categoriesInfos.count == 0 ? 65536 : self.categoriesInfos[0].blockPosition.position / 2
        let blockPosition = BlockPosition(blockId: toggleBlock.id, ownerId: toggleBlock.parentId, position: position)
        
        let blockInfo = BlockInfo(block: toggleBlock,blockPosition: blockPosition)
        
        
        BlockRepo.shared.createBlock(blockInfo)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBoardCategoryInsert(toggleBlock:blockInfo)
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    
    func handleBoardCategoryInsert(toggleBlock:BlockInfo) {
        self.categoriesInfos.insert(toggleBlock, at: 0)
        self.menuSectionTypes.insert(MenuSectionType.boards(groupId: toggleBlock.id), at: self.sectionCategoryBeginIndex)
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([self.sectionCategoryBeginIndex]), with: .automatic)
        }, completion: nil)
    }
    
    
    func handleCategoryMenuEdit(toggleBlockId: String,sourceView: UIView) {
        
        let TAG_ADD = 1
        let TAG_EDIT = 2
        let TAG_DEL = 3
        
        guard let toggleBlock = self.categoriesInfos.first(where: {$0.id == toggleBlockId }) else { return }
        
        let items = [
            ContextMenuItem(label: "添加便签板", icon: "plus.rectangle",tag: TAG_ADD),
            ContextMenuItem(label: "编辑分类", icon: "pencil",tag:TAG_EDIT),
            ContextMenuItem(label: "删除分类", icon: "trash",tag:TAG_DEL)
        ]
        ContextMenuViewController.show(sourceView:sourceView, sourceVC: self, items: items) { [weak self] menuItem, vc in
            vc.dismiss(animated: true, completion: nil)
            guard let self = self,let tag = menuItem.tag as? Int else { return}
            switch tag {
            case TAG_ADD:
                self.openCreateBoardVC(parent: toggleBlock)
                break
            case TAG_EDIT:
                self.showCategoryInputAlert(toggleBlock: toggleBlock)
                break
            case TAG_DEL:
                self.showAlertMessage(message: "确认删除该分类", positiveButtonText: "删除",isPositiveDestructive:true) {
                    self.deleteBoardCategory(toggleBlock:toggleBlock)
                }
                break
            default:
                break
                
            }
        }
    }
    
    
    func updateToggleBlockProperties(toggleBlock:BlockInfo,isReloadSecction:Bool = false) {
        BlockRepo.shared.updateProperties(id: toggleBlock.id, propertiesJSON: toggleBlock.block.propertiesJSON)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBoardCategoryUpdate(toggleBlock:toggleBlock,isReloadSecction:isReloadSecction)
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    
    func updateToggleBlock(toggleBlock:Block) {
        
        //            BlockRepo.shared.getBlocks(parentId: <#T##String#>)
        //            BoardRepo.shared.updateBoardCategory(boardCategory: newBoardCategory)
        //                .subscribe(onNext: { [weak self] isSuccess in
        //                    if isSuccess {
        //                        self?.handleBoardCategoryUpdate(newBoardCategory: newBoardCategory)
        //                    }
        //                    }, onError: { error in
        //                        Logger.error(error)
        //                })
        //                .disposed(by: disposeBag)
    }
    
    func handleBoardCategoryUpdate(toggleBlock: BlockInfo,isReloadSecction:Bool) {
        guard let index = self.categoriesInfos.firstIndex(where: {$0.id == toggleBlock.id}) else { return }
        let section = index + self.sectionCategoryBeginIndex
        self.categoriesInfos[index] = toggleBlock
        
        self.tableView.performBatchUpdates({
            if isReloadSecction {
                self.tableView.reloadSections(IndexSet([section]), with: .automatic)
            }else {
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
            }
        }, completion: nil)
        //            guard let categoryIndex = self.mapCategoryIdAnIndex[newBoardCategory.id] else { return }
        //            let section = getSectionIndex(categoryId: newBoardCategory.id)
        //            if self.boardCategories[categoryIndex].category.isExpand != newBoardCategory.isExpand { // 刷新 section
        //                self.boardCategories[categoryIndex].category = newBoardCategory
        //                self.tableView.performBatchUpdates({
        //                    self.tableView.reloadSections(IndexSet([section]), with: .none)
        //                }, completion: nil)
        //                return
        //            }
        //            self.boardCategories[categoryIndex].category = newBoardCategory
        //            self.tableView.performBatchUpdates({
        //                self.tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .none)
        //            }, completion: nil)
    }
    
    func getSectionIndex(categoryId: String) -> Int {
        //        return (self.mapCategoryIdAnIndex[categoryId] ?? 0 ) + self.sectionCategoryBeginIndex
        return 1
    }
    
    
    func deleteBoardCategory(toggleBlock:BlockInfo) {
        BoardRepo.shared.deleteBoardCategory(toggleBlock, childNewCategory: self.boardGroupBlock)
            .subscribe(onNext: { [weak self] newParent in
                self?.handleBoardCategoryInfoDelete(deletedBlockIanfo:toggleBlock,newParent:newParent)
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    
    func handleBoardCategoryInfoDelete(deletedBlockIanfo:BlockInfo,newParent:BlockInfo) {
        guard let index = self.categoriesInfos.firstIndex(where: {$0.id == deletedBlockIanfo.id}) else { return }
        self.categoriesInfos.remove(at: index)
        let deletedSection = index + self.sectionCategoryBeginIndex
        self.menuSectionTypes.remove(at: deletedSection)
        self.boardGroupBlock = newParent
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet([deletedSection]), with: .none)
            if deletedBlockIanfo.contentBlocks.isNotEmpty {
                self.tableView.reloadSections(IndexSet([1]), with: .none)
            }
        }, completion: nil)
        
    }
    
    func expandOrCollapse(section:Int) {
        var categoryBlockInfo = self.categoriesInfos[section-self.sectionCategoryBeginIndex]
        categoryBlockInfo.blockToggleProperties!.isFolded = !categoryBlockInfo.blockToggleProperties!.isFolded
        self.updateToggleBlockProperties(toggleBlock: categoryBlockInfo,isReloadSecction: true)
    }
    
}

extension SideMenuViewController {
    
    func boardIsUpdated(board:BlockInfo) {
        self.updatedBoard = board
    }
    
    func boardIsDeleted(board:BlockInfo) {
        self.deletedBoard = board
        self.setRowSelected(indexPath: IndexPath(row: 0, section: 0))
    }
    
    func setBoardSelected(boardBlock:BlockInfo) {
        if let indexPath = getBoardIndexPath(boardBlock:boardBlock) {
            self.setRowSelected(indexPath: indexPath)
        }
    }
    
    private func handleUpdateBoard(board:BlockInfo) {
        
        guard let indexPath =  getBoardIndexPath(boardBlock: board) else { return }
        if indexPath.section == 1 {
            self.boardGroupBlock.contentBlocks[indexPath.row-1] = board
        }else {
            let index = indexPath.section - self.sectionCategoryBeginIndex
            self.categoriesInfos[index].contentBlocks[indexPath.row-1] = board
            let isFolded = self.categoriesInfos[index].blockToggleProperties!.isFolded
            if isFolded { // 被折叠
                return
            }
        }
        
        UIView.performWithoutAnimation {
            self.tableView.performBatchUpdates({
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        
    }
    
    private func handleDeleteBoard(board:BlockInfo) {
        
        guard let indexPath =  getBoardIndexPath(boardBlock: board) else { return }
        if indexPath.section == 1 {
            self.boardGroupBlock.contentBlocks.remove(at: indexPath.row-1)
        }else {
            let index = indexPath.section - self.sectionCategoryBeginIndex
            self.categoriesInfos[index].contentBlocks.remove(at: indexPath.row-1)
            let isFolded = self.categoriesInfos[index].blockToggleProperties!.isFolded
            if isFolded { // 被折叠
                return
            }
        }
        
        UIView.performWithoutAnimation {
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        //        setSelected(indexPath: IndexPath(row: 0, section: 0))
        //        guard let indexPath:IndexPath = getBoardIndexPath(board: board) else { return }
        //        if indexPath.section == 1{
        //            self.boards.remove(at: indexPath.row)
        //        }else {
        //            let index = indexPath.section - self.sectionCategoryBeginIndex
        //            self.boardCategories[index].removeBoard(index: indexPath.row-1)
        //            let isExpand = self.boardCategories[index].category.isExpand
        //            if !isExpand { // 被折叠
        //                return
        //            }
        //        }
        //
        //        UIView.performWithoutAnimation {
        //            self.tableView.performBatchUpdates({
        //                self.tableView.deleteRows(at: [indexPath], with: .none)
        //            }, completion: nil)
        //        }
    }
    
    private func getBoardIndexPath(boardBlock:BlockInfo) -> IndexPath?{
        
        if spaceInfo.collectBoard.id == boardBlock.id {
            return IndexPath(row: 0, section: 0)
        }
        
        if let index = self.boardGroupBlock.contentBlocks.firstIndex(of: boardBlock) {
            return IndexPath(row: index+1, section: 1)
        }
        
        
        if let categoryIndex = self.categoriesInfos.firstIndex(where: {$0.id == boardBlock.parentId}),
            let index =  self.categoriesInfos[categoryIndex].contentBlocks.firstIndex(of: boardBlock)
           {
            return IndexPath(row: index+1, section: categoryIndex+sectionCategoryBeginIndex)
        }
        return nil
    }
}



//MARK: board
extension SideMenuViewController {
    func createBoard(emoji: Emoji,title:String,parent:BlockInfo) {
        
        //        guard var parent = self.blocksMap[parentId] else { return }
        //        parent.updatedAt = Date()
        
        let board = Block.newBoardBlock(parentId: parent.id, parentTable: .block, properties: BlockBoardProperty(icon: emoji.value, title: title))
        
        let position = parent.contentBlocks.count > 0 ? parent.contentBlocks[0].blockPosition.position / 2 : 65536
        let blockPosition = BlockPosition(blockId: board.id, ownerId: board.parentId, position: position)
        
        let blockInfo = BlockInfo(block: board, blockPosition: blockPosition)
        
        
        var newParent = parent
        newParent.block.updatedAt = Date()
        newParent.contentBlocks.insert(blockInfo, at: 0)
        
        
        BlockRepo.shared.createBlock(blockInfo)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBoardInsert(parent:newParent)
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    
    private func getSectionIndex(toggleBlockId:String) -> Int? {
        return  self.menuSectionTypes.firstIndex {
            if case .boards(let id) = $0 {
                return id == toggleBlockId
            }
            return false
        }
    }
    
    func handleBoardInsert(parent:BlockInfo) {
        
        var section:Int
        if parent.id == boardGroupBlock.id {
            section = 1
            self.boardGroupBlock = parent
        }else {
            let index = self.categoriesInfos.firstIndex{$0.id == parent.id}!
            self.categoriesInfos[index] = parent
            section = index + self.sectionCategoryBeginIndex
        }
        
        if let isFolded = parent.blockToggleProperties?.isFolded, isFolded == true { // 被折叠
            self.expandOrCollapse(section: section)
            return
        }
        
        self.tableView.performBatchUpdates({
            self.tableView.insertRows(at: [IndexPath(row: 1, section: section)], with: .automatic)
        }, completion: nil)
    }
    
    
    func setSelected(indexPath: IndexPath,selectedItem:SelectedMenuItem) {
        var updatedIndexPaths:[IndexPath]   = []
        
        if let oldSelectedIndexPath = findSelectedIndexPath(selectedItem: self.selectedItem) {
            if let _ = tableView.cellForRow(at: oldSelectedIndexPath) {
                updatedIndexPaths.append(oldSelectedIndexPath)
            }
        }
        updatedIndexPaths.append(indexPath)
        
        self.selectedItem = selectedItem
        self.notifyMenuSelected(selectedIndex: indexPath)
        
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: updatedIndexPaths, with: .none)
        }, completion: nil)
    }
    
    
    func notifyMenuSelected(selectedIndex:IndexPath) {
        let sectionType = self.menuSectionTypes[selectedIndex.section]
        switch sectionType {
        case .system(let items):
            self.delegate?.sideMenuItemSelected(menuItemType:SideMenuItem.system(menuInfo:items[selectedIndex.row]))
        case .boards:
            let boardInfo = getBoardInfo(indexPath: selectedIndex)
            self.delegate?.sideMenuItemSelected(menuItemType: SideMenuItem.board(board: boardInfo))
        }
    }
    
    
    private func isSideMenuSelected(indexPath: IndexPath) -> Bool {
        
        let selectedBoardId = self.selectedItem.boardId
        
        if indexPath.section  == 0 && indexPath.row == 0 {
            return selectedBoardId == self.spaceInfo.collectBoard.id
        }
        
        if indexPath.section  == 0  && indexPath.row == 1{
            return selectedBoardId == ""
        }
        
        
        if indexPath.section  == 1 {
            return selectedBoardId == self.boardGroupBlock.contentBlocks[indexPath.row-1].id
        }
        
        return selectedBoardId == self.categoriesInfos[indexPath.section-self.sectionCategoryBeginIndex].contentBlocks[indexPath.row-1].id
    }
    
    private func findSelectedIndexPath(selectedItem:SelectedMenuItem) -> IndexPath? {
        
        switch selectedItem {
        case .trash:
            return IndexPath(row: 1, section: 0)
        case .board(let groupId, let boardId):
            if boardId == self.spaceInfo.collectBoard.id { return IndexPath(row: 0, section: 0)}
            if groupId == self.boardGroupBlock.id {
                if let index = self.boardGroupBlock.contentBlocks.firstIndex(where: {$0.id == boardId}) {
                    return IndexPath(row: index+1, section: 1)
                }
                return nil
            }
            if let section = self.categoriesInfos.firstIndex(where: {$0.id == groupId}),
               let row =  self.categoriesInfos[section].contentBlocks.firstIndex(where: {$0.id == boardId})
            {
                return IndexPath(row:row+1, section: section+self.sectionCategoryBeginIndex)
            }
            return nil
            
        }
    }
    
    //    func findSideMenuItem(indexPath: IndexPath) -> SideMenuItem {
    //        let sectionType = self.menuSectionTypes[indexPath.section]
    //        switch sectionType {
    //        case .system(let items):
    //            return SideMenuItem.system(menuInfo: items[indexPath.row])
    //        case .boards:
    //            return SideMenuItem.board(board: self.boards[indexPath.row])
    //        case .categories:
    //            let board = getBoardCategoryInfo(section:indexPath.section).boards[indexPath.row-1]
    //            return SideMenuItem.board(board: board)
    //        }
    //    }
    
    //    func findSideMenuItemIndex(sideMenuItem:SideMenuItem) -> IndexPath? {
    //        switch sideMenuItem {
    //        case .system(let sysMenuInfo):
    //            guard let index = self.systemMenuItems.firstIndex(where: {$0 == sysMenuInfo}) else { return nil }
    //            return IndexPath(row: index, section: 0)
    //        case .board(let board):
    //            return getBoardIndexPath(board: board)
    //        }
    //    }
    
    func updateBoard(newBoard:Board,callback:(()->Void)? = nil) {
        //        BoardRepo.shared.updateBoard(board: newBoard)
        //            .subscribe(onNext: { isSuccess in
        //                if isSuccess  {
        //                    if let callback = callback {
        //                        callback()
        //                    }
        //                }
        //            }, onError: { error in
        //                Logger.error(error)
        //            })
        //            .disposed(by: disposeBag)
    }
    
    private func updateBoardDataSource(board: Board) {
        //        if board.categoryId.isNotEmpty {
        //            if let boardIndex = self.boards.firstIndex(where: {$0.id == board.id}) {
        //                let isSortUpdate =  self.boards[boardIndex].sort != board.sort
        //                self.boards[boardIndex] = board
        //                if isSortUpdate {
        //                    self.boards =  self.boards.sorted(by: {$0.sort < $1.sort})
        //                }
        //            }
        //        }else {
        //            if let categoryIndex = self.mapCategoryIdAnIndex[board.categoryId],
        //                let boardIndex =  self.boardCategories[categoryIndex].boards.firstIndex(where: { $0.id == board.id})
        //            {
        //
        //                guard var boards =  self.boardCategories[categoryIndex].boards else { return }
        //
        //                let isSortUpdate = boards[boardIndex].sort != board.sort
        //                boards[boardIndex] = board
        //                if isSortUpdate {
        //                    boards =  boards.sorted(by: {$0.sort < $1.sort})
        //                }
        //                self.boardCategories[categoryIndex].boards = boards
        //
        //
        //            }
        //        }
    }
    
    //    func getBoardSort(boardCategory: BoardCategory?) -> Double {
    //
    //        var boards = self.boards
    //        if let boardCategory = boardCategory {
    //            guard let categoryIndex = self.mapCategoryIdAnIndex[boardCategory.id] else { return 65536}
    //            boards = self.boardCategories[categoryIndex].boards
    //        }
    //
    //        if boards.count == 0 {
    //            return 65536
    //        }
    //        return boards[0].sort / 2
    //    }
    
    func calcSort(toRow:Int,boards:[Board])->Double {
        if boards.count == 0 {
            return 65536
        }
        if toRow == 0 {
            return boards[toRow].sort / 2
        }
        if toRow == boards.count {
            return  boards[toRow-1].sort + 65536
        }
        return (boards[toRow-1].sort + boards[toRow].sort)/2
    }
    
    func calcSort(blocks: inout [BlockInfo],fromRow:Int,toRow:Int) -> Double {
        if toRow == blocks.count - 1 {
            return blocks[blocks.count-1].position + 65536
        }
        if toRow == 0 {
            return blocks[0].position / 2
        }
        if fromRow < toRow {
            return (blocks[toRow].position + blocks[toRow+1].position) / 2
        }
        return (blocks[toRow].position + blocks[toRow-1].position) / 2
    }
    
    
    // 排序处理
    func swapRowInSameSection(section: Int,fromRow: Int, toRow: Int) {
        
        let rightFromRow = fromRow - 1
        let rightToRow = toRow - 1
        
        
        func swapBlockInfo( boardGroupBlock:inout BlockInfo, fromRow: Int, toRow: Int) {
            
            var movedBlockInfo = boardGroupBlock.contentBlocks[rightFromRow]
            movedBlockInfo.position = calcSort(blocks:&boardGroupBlock.contentBlocks, fromRow: fromRow, toRow: toRow)
            
            boardGroupBlock.contentBlocks.remove(at: rightFromRow)
            boardGroupBlock.contentBlocks.insert(movedBlockInfo, at: rightToRow)
        }
        
        
        var boardGroupBlock = getBoardCategory(section: section)
        swapBlockInfo(boardGroupBlock: &boardGroupBlock, fromRow: rightFromRow, toRow: rightToRow)
        
        
        self.boardGroupBlock = boardGroupBlock
        
        // 更新 position
        BoardRepo.shared.updatePosition(blockPosition: boardGroupBlock.contentBlocks[rightToRow].blockPosition)
            .subscribe(onNext: { _ in
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    
    func swapRowCrossSection(fromSection: Int,toSection: Int,fromRow: Int, toRow: Int) {
        
        let rightFromRow = fromRow - 1
        let rightToRow = toRow - 1
        
        func calcPosition(blockInfos: inout [BlockInfo],toRow: Int) -> Double{
            if blockInfos.isEmpty { return 65536}
            if toRow == 0 {
                return blockInfos[0].position / 2
            }
            if toRow == blockInfos.count {
                return blockInfos[blockInfos.count-1].position + 65536
            }
            
            return (blockInfos[toRow].position + blockInfos[toRow-1].position) / 2
        }
        
        func updateDataSource(fromBlockGroup:inout BlockInfo,toBlockGroup: inout BlockInfo) {
            if fromBlockGroup.id == self.boardGroupBlock.id {
                self.boardGroupBlock = fromBlockGroup
            }else {
                self.categoriesInfos[fromSection-self.sectionCategoryBeginIndex] = fromBlockGroup
            }
            if toBlockGroup.id == self.boardGroupBlock.id {
                self.boardGroupBlock = toBlockGroup
            }else {
                self.categoriesInfos[toSection-self.sectionCategoryBeginIndex] = toBlockGroup
            }
        }
        
        var fromBlockGroup:BlockInfo = getBoardCategory(section: fromSection)
        var toBlockGroup:BlockInfo  = getBoardCategory(section: toSection)
        
        var movedBlockInfo = fromBlockGroup.contentBlocks[rightFromRow]
        movedBlockInfo.block.parentId = toBlockGroup.id
        movedBlockInfo.blockPosition.ownerId = toBlockGroup.id
        movedBlockInfo.blockPosition.position = calcPosition(blockInfos: &toBlockGroup.contentBlocks, toRow: rightToRow)
        
        fromBlockGroup.contentBlocks.remove(at: rightFromRow)
        toBlockGroup.contentBlocks.insert(movedBlockInfo, at: rightToRow)
        
        updateDataSource(fromBlockGroup: &fromBlockGroup, toBlockGroup: &toBlockGroup)
        
        // 更新 position
        BoardRepo.shared.updatePositionAndParent(blockPosition: toBlockGroup.contentBlocks[rightToRow].blockPosition)
            .subscribe(onNext: { _ in
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        // 更新 数据源
        
        
    }
    
    private func pringBoards(boards:[Board]) {
        print("*****************************")
        boards.forEach { print(" \($0.icon) ---  \($0.sort)")  }
        print("*****************************")
    }
}


//MARK: UITableViewDelegate
extension SideMenuViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = self.menuSectionTypes[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: getCellIdentifier(sectionType: sectionType, indexPath: indexPath))!
        switch sectionType {
        case .system(let items):
            let sysCell = cell as! MenuSystemCell
            sysCell.menuSysItem = items[indexPath.row]
            sysCell.cellIsSelected = isSideMenuSelected(indexPath: indexPath)
            break
        case .boards:
            let blockInfo = indexPath.section == 1 ? boardGroupBlock : categoriesInfos[indexPath.section-self.sectionCategoryBeginIndex]
            if indexPath.row == 0 {
                let categoryCell = cell as! MenuCategoryCell
                categoryCell.toggleBlock = blockInfo.block
                categoryCell.callbackMenuTapped = { [weak self] button,parentId in
                    self?.handleCategoryMenuEdit(toggleBlockId: parentId, sourceView: button)
                }
            }else {
                let board = blockInfo.contentBlocks[indexPath.row-1]
                let boardCell = cell as! MenuBoardCell
                boardCell.board = board.block
                boardCell.cellIsSelected = isSideMenuSelected(indexPath: indexPath)
            }
        }
        return cell
    }
    
    
    private func getCellIdentifier(sectionType:MenuSectionType,indexPath:IndexPath) -> String {
        switch sectionType {
        case .system:
            return CellReuseIdentifier.system.rawValue
        case .boards:
            if indexPath.row == 0 {
                return CellReuseIdentifier.category.rawValue
            }
            return CellReuseIdentifier.board.rawValue
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .system:
            return MenuHeaderView()
        default:
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .boards:
            return indexPath.row > 0
        default:
            return false
        }
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromSection = sourceIndexPath.section
        let toSection = destinationIndexPath.section
        
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        
        if fromSection != toSection {
            swapRowCrossSection(fromSection: fromSection, toSection: toSection, fromRow: fromRow, toRow: toRow)
        }else {
            swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
        }
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let boardCategory = getBoardCategory(section: proposedDestinationIndexPath.section)
        if boardCategory.blockToggleProperties?.isFolded == true {
            
            var returnRow = 1
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                returnRow = getBoardCategory(section: sourceIndexPath.section).contentBlocks.count
            }
            return IndexPath(row: returnRow, section: sourceIndexPath.section)
        }
        
        if proposedDestinationIndexPath.row == 0 {
            return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
        }
        return proposedDestinationIndexPath
    }
    
    
    static func generateCellSelectedView() ->UIView {
        return UIView().then {
            $0.backgroundColor = .sidemenuSelectedBg
            let cornerRadius:CGFloat = 8
            $0.layer.cornerRadius = CGFloat(cornerRadius)
            $0.clipsToBounds = true
            $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            $0.isHidden = true
        }
    }
    
}


//MARK: UITableViewDataSource
extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.menuSectionTypes[section] {
        case .system(let items):
            return items.count
        case .boards:  // 分类作为单独一个 cell
            if section == 1 { return boardGroupBlock.contentBlocks.count + 1 }
            let categoryBlockInfo = self.categoriesInfos[section-self.sectionCategoryBeginIndex]
            if categoryBlockInfo.blockToggleProperties!.isFolded {
                return 1
            }
            return categoryBlockInfo.contentBlocks.count + 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSectionTypes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            return 42
        default:
            return 42
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionSpace:CGFloat  = 16
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .system:
            return 44
        case .boards:
            if section == 1 { return 0}
            if getBoardCategory(section: section-1).blockToggleProperties?.isFolded == true {
                return 0
            }
            return sectionSpace
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.setRowSelected(indexPath: indexPath)
    }
    
    private func setRowSelected(indexPath:IndexPath) {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            let selectedItem =  indexPath.row == 0 ? SelectedMenuItem.board(groupId: "", boardId: self.spaceInfo.collectBoard.id) : SelectedMenuItem.trash
            self.setSelected(indexPath: indexPath, selectedItem:selectedItem )
            break
        case .boards(let groupId):
            if indexPath.row > 0 {
                let selectedId = getBoardInfo(indexPath: indexPath).id
                let selectedItem = SelectedMenuItem.board(groupId: groupId, boardId:selectedId)
                self.setSelected(indexPath: indexPath,selectedItem: selectedItem)
                
            }else if indexPath.section > 1{
                self.expandOrCollapse(section: indexPath.section)
            }
            break
        }
    }
    
    private func getBoardInfo(indexPath:IndexPath) -> BlockInfo {
        return getBoardCategory(section: indexPath.section).contentBlocks[indexPath.row-1]
    }
    
    private func getBoardCategory(section:Int) -> BlockInfo {
        if section == 1 {
            return self.boardGroupBlock
        }
        return self.categoriesInfos[section-self.sectionCategoryBeginIndex]
    }
}


// drag and drop
extension SideMenuViewController: UITableViewDragDelegate, UITableViewDropDelegate  {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}


enum MenuSectionType {
    case system(items: [MenuSystemItem])
    case boards(groupId:String)
}

fileprivate enum CellReuseIdentifier: String {
    case system = "system"
    case board = "boards"
    case category = "category"
}

enum MenuSystemItem:Equatable {
    case board(board: BlockInfo)
    case trash(icon:String,title:String)
    
    static func == (lhs: MenuSystemItem, rhs: MenuSystemItem) -> Bool {
        switch (lhs,rhs)  {
        case (.board(let lmenu),.board(let rmenu) ):
            return  lmenu.id == rmenu.id
        case (.board,.trash):
            return false
        case (.trash,.trash):
            return true
        case (.trash(icon:  _, title:  _), .board(board: _)):
            return false
        }
    }
    
    var icon:String {
        switch self {
        case .board(let board):
            return board.blockBoardProperties?.icon ?? ""
        case .trash(let icon,_):
            return icon
        }
    }
    
    var iconImage:UIImage? {
        return UIImage(systemName: icon, pointSize: 15, weight: .regular)
    }
    
    var title:String {
        switch self {
        case .board(let board):
            return board.blockBoardProperties?.title ?? ""
        case .trash(_,let title):
            return title
        }
    }
}
