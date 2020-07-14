//
//  ChangeBoardViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import RxSwift

class ChangeBoardViewController:UIViewController {
    
    private var menuSectionTypes:[BoardSectionType] = []
    private var systemMenuItems:[MenuSystemItem]  =  []
    private var boards:[Board] = []
    private var mapCategoryIdAnIndex:[String:Int]  = [:]
    private var boardCategories:[BoardCategoryInfo] = [] {
        didSet {
            self.mapCategoryIdAnIndex.removeAll()
            for (index,boardCategoryInfo) in boardCategories.enumerated() {
                mapCategoryIdAnIndex[boardCategoryInfo.category.id] = index
            }
        }
    }
    
    var callbackBoardChoosed:((Board)->Void)?
    
    
    var note:Note! {
        didSet {
            if oldValue == nil {
                self.loadBoards()
            }
        }
    }
    var choosedBoards:[Board] = []
    
    private let cellReuseIndentifier = "ChangeBoardCell"
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.separatorColor = UIColor.clear
        $0.delegate = self
        $0.dataSource = self
        $0.showsVerticalScrollIndicator = false
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        $0.register(ChangeBoardCell.self, forCellReuseIdentifier: self.cellReuseIndentifier)
    }
    
    private lazy var  cellBackgroundView = UIView().then {
          $0.backgroundColor = UIColor.tappedColor
      }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        self.tableView.backgroundColor = .white
        
        
        self.title = "移动至..."
         
    }
    
    private func loadBoards() {
        
//        BoardRepo.shared.getBoardCategoryInfos(noteId:self.note.id)
//            .subscribe(onNext: { [weak self] result in
//                self?.setupData(boardsResult:result)
//                }, onError: { err in
//                    Logger.error(err)
//            })
//            .disposed(by: disposeBag)
    }
    
    private func setupData(boardsResult:(Board?,BoardInfo)) {
        let boardInfo = boardsResult.1
        
        let board = boardsResult.0
        self.choosedBoards = board == nil ? [] : [board!]
        
//        let systemBoards = boardInfo.systemBoards
//        self.boards = boardInfo.boards
//
//        self.boardCategories = boardInfo.boardCategoryInfos
        
//        self.menuSectionTypes.append(BoardSectionType.system(systemBoards: systemBoards))
        if self.boards.isNotEmpty {
            self.menuSectionTypes.append(BoardSectionType.boards)
        }
        if self.boardCategories.isNotEmpty {
            self.menuSectionTypes.append(BoardSectionType.categories)
        }
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension ChangeBoardViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.menuSectionTypes.count
    }
    
    func getCategoryIndex(section:Int) -> Int {
        var index = 1
        if self.boards.count > 0 {
            index += 1
        }
        return section - index
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.menuSectionTypes[section] {
        case .system(let boards):
            return boards.count
        case .boards:
            return self.boards.count
        case .categories: // 分类作为单独一个 cell
            let categoryInfo = self.boardCategories[self.getCategoryIndex(section: section)]
            return categoryInfo.boards.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIndentifier) as! ChangeBoardCell
        let sectionType = self.menuSectionTypes[indexPath.section]
        var board:Board!
        switch sectionType {
        case .system(let systemBoards):
            board = systemBoards[indexPath.row]
            break
        case .boards:
            board  = self.boards[indexPath.row]
        case .categories:
            board = self.boardCategories[self.getCategoryIndex(section: indexPath.section)].boards[indexPath.row]
        }
        cell.board = board
        cell.isChoosed = self.choosedBoards.contains(board)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if case BoardSectionType.categories = self.menuSectionTypes[section] {
            return self.boardCategories[self.getCategoryIndex(section: section)].category.title
        }
        return ""
    }
    

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if case BoardSectionType.categories = self.menuSectionTypes[section] {
            return ContextMenuCell.cellHeight
        }
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}


extension ChangeBoardViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ContextMenuCell.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionType = self.menuSectionTypes[indexPath.section]
        var board:Board!
        switch sectionType {
        case .system(let systemBoards):
            board = systemBoards[indexPath.row]
        case .boards:
             board = self.boards[indexPath.row]
        case .categories:
             board = self.boardCategories[self.getCategoryIndex(section: indexPath.section)].boards[indexPath.row]
        }
        if self.choosedBoards.contains(board) {
            self.navigationController?.popViewController(animated: true)
            return
        }
        self.callbackBoardChoosed?(board)
    }
    
    func toggleBoard(_ board:Board,indexPath:IndexPath) {
        if let index = self.choosedBoards.firstIndex(where: {$0.id == board.id}) {
            self.choosedBoards.remove(at: index)
        }else {
            self.choosedBoards.append(board)
        }

        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }, completion: nil)
    }
}
