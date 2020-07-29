//
//  ChangeBoardViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import RxSwift


enum BlockBoardSectionType {
    case system(systemBoards: [BlockInfo])
    case boards(boardGroup: BlockInfo)
}

class ChangeBoardViewController:UIViewController {
    
    private var sections:[BlockBoardSectionType] = []
    
    var noteInfo:NoteInfo!
    var callbackChooseBoard:((BlockInfo)->Void)!
    
    
    private let cellReuseIndentifier = "ChangeBoardCell"
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
//        $0.separatorColor = UIColor.clear
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
        self.loadBoards()
    }
    
    private func setupUI() {
        let cancelButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        self.title = "移动至..."

//        let barButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(self.doneButtonTapped))
//                barButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.brand], for: .normal)
//        self.navigationItem.rightBarButtonItem = barButtonItem
//        self.navigationController?.navigationBar.barTintColor = .bg
        
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        self.tableView.backgroundColor = .bg
        
        
        self.title = "移动至..."
         
    }
    
    private func loadBoards() {
        // 获取 board
        SpaceRepo.shared.getSpace()
            .subscribe {
                self.setupData(spaceInfo: $0)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupData(spaceInfo: SpaceInfo) {
        
        sections.append(BlockBoardSectionType.system(systemBoards: [spaceInfo.collectBoard]))
        
        let boardsGroups = [spaceInfo.boardGroupBlock] + spaceInfo.categoryGroupBlock.contentBlocks
        for boardGroup in boardsGroups {
            sections.append(BlockBoardSectionType.boards(boardGroup: boardGroup))
        }
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

//    @objc func doneButtonTapped() {
//        self.dismiss(animated: true, completion: nil)
//    }
}

extension ChangeBoardViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sections[section] {
        case .system(let boards):
            return boards.count
        case .boards(let boardGroup):
            return boardGroup.contentBlocks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIndentifier) as! ChangeBoardCell
        var boardBlock:BlockInfo!
        switch self.sections[indexPath.section] {
        case .system(let boards):
            boardBlock = boards[indexPath.row]
        case .boards(let boardGroup):
            boardBlock = boardGroup.contentBlocks[indexPath.row]
        }
        cell.board = boardBlock
        cell.isChoosed = boardBlock.id  == self.noteInfo.noteBlock.blockPosition.ownerId
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if case .boards(let boardGroup) =  self.sections[section] {
            return boardGroup.blockToggleProperties?.title ?? ""
        }
        
        return ""
    }
    

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0  { return 20 }
        if  case .boards(let toggleGroup) =  self.sections[section] {
            if toggleGroup.blockToggleProperties!.title.isEmpty {
                return 20
            }
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
        var boardBlock:BlockInfo!
        switch self.sections[indexPath.section] {
        case .system(let boards):
            boardBlock = boards[indexPath.row]
        case .boards(let boardGroup):
            boardBlock = boardGroup.contentBlocks[indexPath.row]
        }
        self.moveToBoard(boardBlock)
    }
    
    func moveToBoard(_ boardBlock:BlockInfo) {
//        self.noteInfoModel.moveBoard(boardId: boardBlock.id)
        callbackChooseBoard(boardBlock)
        self.dismiss(animated: true, completion: nil)
    }
    
    func toggleBoard(_ board:Board,indexPath:IndexPath) {
//        if let index = self.choosedBoards.firstIndex(where: {$0.id == board.id}) {
//            self.choosedBoards.remove(at: index)
//        }else {
//            self.choosedBoards.append(board)
//        }
//
//        self.tableView.performBatchUpdates({
//            self.tableView.reloadRows(at: [indexPath], with: .none)
//        }, completion: nil)
    }
}
