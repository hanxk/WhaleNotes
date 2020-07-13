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
    case board(board:Block)
    
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

class SideMenuViewController: UIViewController {
    
    private var menuSectionTypes:[MenuSectionType] = []
    
    var space:Space!
    var blocksMap:[String:Block] = [:]
    
    private let disposeBag = DisposeBag()
    weak var delegate:SideMenuViewControllerDelegate? = nil {
        didSet {
            self.loadBoards()
        }
    }
    
    var sectionSpecial = -1
    
    private var deletedBoard: Block?
    private var updatedBoard: Block?
    
    private var selectedMenuItem:SideMenuItem! {
        
        didSet {
            if oldValue != selectedMenuItem {
                delegate?.sideMenuItemSelected(menuItemType: selectedMenuItem)
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
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
                    self.openCreateBoardVC(parentId: self.space.boardGroupIds[0])
                }else {
                    self.showCategoryInputAlert()
                }
            }
            
        }
        
    }
    
    private func openCreateBoardVC(parentId:String) {
        let vc = CreateBoardViewController()
        vc.callbackPositive = {emoji,title in
            self.createBoard(emoji: emoji, title: title,parentId: parentId)
        }
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
        private func showCategoryInputAlert(toggleBlock:Block? = nil) {
            let ac = UIAlertController(title: toggleBlock == nil ? "添加分类" : "编辑分类", message: nil, preferredStyle: .alert)
            ac.addTextField()
            ac.textFields![0].placeholder = "输入分类名称"
            ac.textFields![0].text = toggleBlock == nil ? "" :  toggleBlock!.blockToggleProperties!.title
    
            let submitAction = UIAlertAction(title: "确定", style: .default) { [unowned ac] _ in
                let title = ac.textFields![0].text!.trimmingCharacters(in: .whitespaces)
                if title.isEmpty { return }
                if let toggleBlock = toggleBlock {
                    var newToggleBlock  = toggleBlock
                    newToggleBlock.updatedAt = Date()
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
            .flatMap { space -> Observable<[Block]> in
                self.space = space
                return BlockRepo.shared.getBlocks(parentId: space.id)
            }
            .subscribe {
                self.setupData(blocks: $0)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    
    private func setupData(blocks:[Block]) {
        
        for block in blocks {
            if let boardType =  block.blockBoardProperties?.type,boardType == .collect {
                blocksMap[block.id] = Block.convert2LocalSystemBoard(board: block)
                continue
            }
            blocksMap[block.id] = block
        }
        
        let collectBoard:Block = blocksMap[self.space.collectBoardId]!
        
        let systemMenuItems =  [
            MenuSystemItem.board(board: collectBoard),
            MenuSystemItem.trash(icon: "trash", title: "废纸篓")
        ]
        menuSectionTypes.removeAll()
        
        self.systemMenuItems = systemMenuItems
        menuSectionTypes.append(MenuSectionType.system(items:systemMenuItems))
        
        for groupId in  space.boardGroupIds {
            menuSectionTypes.append(MenuSectionType.boards(groupId: groupId))
        }
    }
    
}


//MARK: board 分类
extension SideMenuViewController {
    
    func createToggleBlock(title:String) {
        let toggleBlock = Block.newToggleBlock(parent: space.id, parentTable: .space, properties: BlockToggleProperty(title: title))
        
        var newSpace = self.space!
        newSpace.boardGroupIds.insert(toggleBlock.id, at: 1)
        
        BlockRepo.shared.createBlock(toggleBlock,parent:newSpace)
            .subscribe(onNext: { [weak self] childAndParent in
                self?.handleToggleInsert(toggleBlock:childAndParent.0,space: childAndParent.1)
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    
    func handleToggleInsert(toggleBlock:Block,space:Space) {
        self.space = space
        self.blocksMap[toggleBlock.id] = toggleBlock
        
        let section = 2
        self.menuSectionTypes.insert(MenuSectionType.boards(groupId: toggleBlock.id), at: 2)
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([section]), with: .automatic)
        }, completion: nil)
        
    }
    
    //    func handleBoardCategoryInsert(insertedBoardCategory: BoardCategory) {
    //        self.boardCategories.insert(BoardCategoryInfo(category: insertedBoardCategory, boards: []), at: 0)
    //        self.menuSectionTypes.insert(MenuSectionType.categories, at: sectionCategoryBeginIndex)
    //        self.tableView.performBatchUpdates({
    //            self.tableView.insertSections(IndexSet([sectionCategoryBeginIndex]), with: .automatic)
    //        }, completion: { _ in
    //            DispatchQueue.main.async {
    //                let indexPath = IndexPath(item:0, section: self.sectionCategoryBeginIndex)
    //                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    //            }
    //        })
    //    }
    
    
    func handleCategoryMenuEdit(toggleBlockId: String,sourceView: UIView) {
        
        let TAG_ADD = 1
        let TAG_EDIT = 2
        let TAG_DEL = 3
        
        guard let toggleBlock = self.blocksMap[toggleBlockId] else { return }


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
                self.openCreateBoardVC(parentId: toggleBlock.id)
            case TAG_EDIT:
                self.showCategoryInputAlert(toggleBlock: toggleBlock)
                break
            case TAG_DEL:
                self.showAlertMessage(message: "确认删除该分类", positiveButtonText: "删除",isPositiveDestructive:true) {
                    self.deleteBoardCategory(toggleBlock: toggleBlock)
                }
                break
            default:
                break

            }
        }
    }
    
    
    func updateToggleBlockProperties(toggleBlock:Block,isReloadSecction:Bool = false) {
        BlockRepo.shared.updateProperties(id: toggleBlock.id, propertiesJSON: toggleBlock.propertiesJSON)
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
    
        func handleBoardCategoryUpdate(toggleBlock: Block,isReloadSecction:Bool) {
            self.blocksMap[toggleBlock.id] = toggleBlock
            
            guard let section = getSectionIndex(toggleBlockId: toggleBlock.id) else { return }
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
    
    
        func deleteBoardCategory(toggleBlock:Block) {
            
            guard var newParent = self.blocksMap[self.space.boardGroupIds[0]] else {
                return
            }
            
            newParent.updatedAt = Date()
            newParent.content.insert(contentsOf: toggleBlock.content, at: 0)
            
            var newSpace = self.space!
            newSpace.boardGroupIds.remove(at: newSpace.boardGroupIds.firstIndex(of: toggleBlock.id)!)
            
            
            BlockRepo.shared.deleteBlock(id: toggleBlock.id, childNewParent: newParent,newSpace: newSpace)
                .subscribe(onNext: { [weak self] _ in
                    self?.handleBoardCategoryInfoDelete(deletedToggleBlock: toggleBlock, newParent: newParent, newSpace: newSpace)
                    }, onError: { error in
                        Logger.error(error)
                })
                .disposed(by: disposeBag)
        }
    
    
    func handleBoardCategoryInfoDelete(deletedToggleBlock: Block,newParent:Block,newSpace:Space) {
        
    guard let deletedSection = getSectionIndex(toggleBlockId: deletedToggleBlock.id),
          let newSection = getSectionIndex(toggleBlockId: newParent.id)
          else { return }
        
        self.space = newSpace
        
        self.menuSectionTypes.remove(at: deletedSection)
        
        self.blocksMap[newParent.id] = newParent
        self.blocksMap.removeValue(forKey: deletedToggleBlock.id)
        
        // 刷新 child
        for child in newParent.content {
            self.blocksMap[child]?.parentId = newParent.id
        }
        
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet([deletedSection]), with: .automatic)
            self.tableView.reloadSections(IndexSet([newSection]), with: .automatic)
//            self.tableView.insertRows(at: [IndexPath(row: 1, section: newSection)], with: .automatic)
            
        }, completion: nil)

    }
    //        //移除 category
    //        guard let categoryIndex = self.mapCategoryIdAnIndex[boardCategoryInfo.category.id] else { return }
    //
    //        let section = categoryIndex + self.sectionCategoryBeginIndex
    //
    //        self.boards.insert(contentsOf: boardCategoryInfo.boards, at: 0)
    //        self.pringBoards(boards: self.boards)
    //
    //        self.menuSectionTypes.remove(at: section)
    //        self.boardCategories.remove(at: categoryIndex)
    //
    //        var updatedRowsIndexPath:[IndexPath] = []
    //        for (index,_) in  boardCategoryInfo.boards.enumerated() {
    //            updatedRowsIndexPath.append(IndexPath(row: index, section: 1))
    //        }
    //
    //        self.tableView.performBatchUpdates({
    //            self.tableView.deleteSections(IndexSet([2+categoryIndex]), with: .none)
    //            self.tableView.insertRows(at: updatedRowsIndexPath, with: .automatic)
    //        }, completion: nil)
    //    }
    
    func expandOrCollapse(section:Int) {
        //        if var  category = self.boardCategories[section-2].category {
        //            category.isExpand = !category.isExpand
        //            self.updateBoardCayegory(newBoardCategory: category)
        //        }
        guard var newToggleTask = self.blocksMap[self.space.boardGroupIds[section-1]],
              var newToggleProperties = newToggleTask.blockToggleProperties else { return }
        
        newToggleProperties.isFolded = !newToggleProperties.isFolded
        newToggleTask.blockToggleProperties = newToggleProperties
        
        self.updateToggleBlockProperties(toggleBlock: newToggleTask,isReloadSecction: true)
        
        
    }
    
}

extension SideMenuViewController {
    
    func boardIsUpdated(board:Block) {
        self.updatedBoard = board
    }
    
    func boardIsDeleted(board:Block) {
        self.deletedBoard = board
        setSelected(indexPath: IndexPath(row: 0, section: 0))
    }
    
    func setBoardSelected(board:Block) {
        if let indexPath = getBoardIndexPath(board: board) {
            setSelected(indexPath: indexPath)
        }
    }
    
    private func handleUpdateBoard(board:Block) {
        guard let indexPath:IndexPath = getBoardIndexPath(board: board) else { return }
        //        if indexPath.section == 1{
        //            self.boards[indexPath.row] = board
        //        }else {
        //            let index = indexPath.section - self.sectionCategoryBeginIndex
        //            self.boardCategories[index].boards[indexPath.row-1] = board
        //            let isExpand = self.boardCategories[index].category.isExpand
        //            if !isExpand { // 被折叠
        //                return
        //            }
        //        }
        //
        //
        //        UIView.performWithoutAnimation {
        //            self.tableView.performBatchUpdates({
        //                self.tableView.reloadRows(at: [indexPath], with: .none)
        //            }, completion: nil)
        //        }
        
    }
    
    private func handleDeleteBoard(board:Block) {
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
    
    private func getBoardIndexPath(board:Block) -> IndexPath?{
        //        var indexPath:IndexPath?
        //        if let index = self.boards.firstIndex(where: {$0.id == board.id}) {
        //            indexPath = IndexPath(row: index, section: 1)
        //        }else {
        ////            for (_,category) in self.boardCategories.enumerated() {
        ////                if let row = category.boards.firstIndex(where: {$0.id == board.id}) {
        ////                    indexPath = IndexPath(row: row+1, section: getSectionIndex(categoryId: category.category.id))
        ////                    break
        ////                }
        ////            }
        //        }
        //        return indexPath
        return nil
    }
}



//MARK: board
extension SideMenuViewController {
    func createBoard(emoji: Emoji,title:String,parentId:String) {
        
        guard var parent = self.blocksMap[parentId] else { return }
        
        let board = Block.newBoardBlock(parentId: parentId, parentTable: .block, properties: BlockBoardProperty(icon: emoji.value, title: title))
        parent.updatedAt = Date()
        parent.content.insert(board.id, at: 0)
        
        
        BlockRepo.shared.createBlock(board,parent: parent)
            .subscribe(onNext: { [weak self] childAndParent in
                self?.handleBoardInsert(insertedBoard:childAndParent.0,parent: childAndParent.1)
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
    
    func handleBoardInsert(insertedBoard: Block,parent:Block) {
        self.blocksMap[insertedBoard.id] = insertedBoard
        self.blocksMap[parent.id] = parent
        
        guard let section = getSectionIndex(toggleBlockId: parent.id) else { return }
        self.tableView.performBatchUpdates({
            self.tableView.insertRows(at: [IndexPath(row: 1, section: section)], with: .automatic)
        }, completion: nil)
    }
    
    
    func setSelected(indexPath: IndexPath) {
        
        var updatedIndexPaths:[IndexPath]   = []
        if let sideMenuItem = self.selectedMenuItem,
           let oldSelectedIndexPath = findSideMenuItemIndex(sideMenuItem: sideMenuItem) {
            if let _ = tableView.cellForRow(at: oldSelectedIndexPath) { // cell 可能会被折叠
                updatedIndexPaths.append(oldSelectedIndexPath)
            }
        }
        
        //        self.selectedMenuItem = findSideMenuItem(indexPath: indexPath)
        updatedIndexPaths.append(indexPath)
        
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: updatedIndexPaths, with: .none)
        }, completion: nil)
    }
    
    
    private func isSideMenuSelected(indexPath: IndexPath) -> Bool {
        //        return self.selectedMenuItem == findSideMenuItem(indexPath: indexPath)
        return false
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
    
    func findSideMenuItemIndex(sideMenuItem:SideMenuItem) -> IndexPath? {
        switch sideMenuItem {
        case .system(let sysMenuInfo):
            guard let index = self.systemMenuItems.firstIndex(where: {$0 == sysMenuInfo}) else { return nil }
            return IndexPath(row: index, section: 0)
        case .board(let board):
            return getBoardIndexPath(board: board)
        }
    }
    
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
    
    
    // 排序处理
    func swapRowInSameSection(section: Int,fromRow: Int, toRow: Int) {
        //        if case .boards = self.menuSectionTypes[section] {
        //
        //            var board = self.boards[fromRow]
        //            self.boards.remove(at: fromRow)
        //
        //            board.sort = calcSort(toRow: toRow, boards: self.boards)
        //            self.boards.insert(board, at: toRow)
        //
        //            self.updateBoard(newBoard: board) {
        //                self.pringBoards(boards: self.boards)
        //            }
        //        }else {
        //
        //            let newBoard = self.boardCategories[section-2].swapBoard(from: fromRow-1, to: toRow-1)
        //            self.updateBoard(newBoard: newBoard) {
        //                self.pringBoards(boards: self.boardCategories[section-2].boards)
        //            }
        //
        //
        //        }
    }
    
    //    func getBoardCategoryInfo(section:Int) -> BoardCategoryInfo {
    //        return self.boardCategories[section - self.sectionCategoryBeginIndex]
    //    }
    
    
    func swapRowCrossSection(fromSection: Int,toSection: Int,fromRow: Int, toRow: Int) {
        
        var board:Board?
        // 移除 from 中的 board
        //        if case .categories = self.menuSectionTypes[fromSection] {
        //            board = self.boardCategories[fromSection - self.sectionCategoryBeginIndex].boards[fromRow-1]
        //            self.boardCategories[fromSection - self.sectionCategoryBeginIndex].removeBoard(index:  fromRow - 1)
        //        }else {
        //            board = self.boards[fromRow]
        //            self.boards.remove(at: fromRow)
        //        }
        
        //        guard var fromBoard = board else { return }
        //
        //        if case .categories = self.menuSectionTypes[toSection] {
        
        //            var boardCategoryInfo = getBoardCategoryInfo(section: toSection)
        //            fromBoard.categoryId = boardCategoryInfo.categoryId
        //            fromBoard.sort =  self.calcSort(toRow: toRow-1, boards: boardCategoryInfo.boards)
        //            boardCategoryInfo.boards.insert(fromBoard, at: toRow-1)
        //
        //            self.boardCategories[toSection - self.sectionCategoryBeginIndex] = boardCategoryInfo
        //
        //            let isExpand = boardCategoryInfo.category.isExpand
        //            if !isExpand {
        //
        //                // 先显示，然后再删除
        //                sectionSpecial = toSection
        //                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3) {
        //                    self.tableView.performBatchUpdates({
        //                        self.tableView.reloadSections(IndexSet([toSection]), with: .fade)
        //                    }, completion: nil)
        //                }
        //            }
        //
        //            self.pringBoards(boards: boardCategoryInfo.boards)
        
        
        //        }else {
        //            fromBoard.sort =  self.calcSort(toRow: toRow, boards: self.boards)
        //            fromBoard.categoryId = ""
        //
        //            self.boards.insert(fromBoard, at: toRow)
        //
        //            self.pringBoards(boards: self.boards)
        //
        //
        //        }
        //
        //        self.updateBoard(newBoard: fromBoard)
        
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
        case .boards(let groupId):
            let toggleBlock = self.blocksMap[groupId]!
            if indexPath.row == 0 {
                let categoryCell = cell as! MenuCategoryCell
                categoryCell.toggleBlock = toggleBlock
                categoryCell.callbackMenuTapped = { [weak self] button,parentId in
                    self?.handleCategoryMenuEdit(toggleBlockId: parentId, sourceView: button)
                }
            }else {
                let board = self.blocksMap[toggleBlock.content[indexPath.row-1]]!
                let boardCell = cell as! MenuBoardCell
                boardCell.board = board
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
            return true
        //        case .categories:
        //            return indexPath.row > 0 //第一行是 group title
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
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        let sourSectionType = self.menuSectionTypes[sourceSection]
        let desSectionType = self.menuSectionTypes[destSection]
        
        
        //        switch desSectionType {
        //        case .boards:
        //            return proposedDestinationIndexPath
        //        case .categories:
        //            if proposedDestinationIndexPath.row == 0 {
        //                return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
        //            }
        //            return proposedDestinationIndexPath
        //        case .system:
        //            if destSection > sourceSection {
        //                return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
        //            }
        //            if case .categories  = sourSectionType {
        //                return IndexPath(row: 1, section: sourceSection)
        //            }
        //            return IndexPath(row: 0, section: sourceSection)
        //
        //        }
        return IndexPath(row: 0, section: sourceSection)
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
        case .boards(let groupId):  // 分类作为单独一个 cell
            let toggleTask = self.blocksMap[groupId]!
            if toggleTask.blockToggleProperties!.isFolded {
                return 1
            }
            return toggleTask.content.count + 1
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
        let sectionSpace:CGFloat  = 20
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .system:
            return 44
        case .boards:
//            return section > 1 ? 0 : sectionSpace
            return 0
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
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            self.setSelected(indexPath: indexPath)
            break
        case .boards:
            if indexPath.row > 0 {
                self.setSelected(indexPath: indexPath)
            }else if indexPath.section > 1{
                self.expandOrCollapse(section: indexPath.section)
            }
            break
        }
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
    case board(board: Block)
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
