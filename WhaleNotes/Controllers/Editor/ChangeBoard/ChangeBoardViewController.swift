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
    case boards(userBoards: [BlockInfo])
}

class ChangeBoardViewController:UIViewController {
    
    private var sections:[BlockBoardSectionType] = []
    
//    var choosedBoard:BlockInfo!
//    var callbackChooseBoard:((BlockInfo)->Void)?
    var viewModel:CardEditorViewModel!
    private var choosedBoard:BlockInfo {
        return viewModel.board
    }
    
    
    private let cellReuseIndentifier = "ChangeBoardCell"
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.showsVerticalScrollIndicator = false
//        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
//        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
//        $0.register(ChangeBoardCell.self, forCellReuseIdentifier: self.cellReuseIndentifier)
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
        self.title = "移动至..."
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        self.tableView.backgroundColor = .settingbg
        
        self.title = "移动至..."
         
    }
    
    private func loadBoards() {
        BoardsRepo.shared.getBoards()
            .subscribe {
                self.setupData(boards: $0)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupData(boards:[BlockInfo]) {
        
        guard let collectBoard =  boards.first(where: {$0.blockBoardProperties!.type == .collect}) else { return }
        let userBoards =  boards.filter({ $0.blockBoardProperties!.type == .user}).sorted(by: {$0.position < $1.position})
        
        sections.append(BlockBoardSectionType.system(systemBoards: [collectBoard]))
        sections.append(BlockBoardSectionType.boards(userBoards: userBoards))
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ChangeBoardViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sections[section] {
        case .system(let boards):
            return boards.count
        case .boards(let userBoards):
            return userBoards.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var boardBlock:BlockInfo!
        var iconImage:UIImage!
        let fontSize:CGFloat = 18
        switch self.sections[indexPath.section] {
        case .system(let boards):
            boardBlock = boards[indexPath.row]
            iconImage = UIImage(systemName: boardBlock.blockBoardProperties!.icon)
        case .boards(let boards):
            boardBlock = boards[indexPath.row]
            iconImage =  boardBlock.blockBoardProperties!.icon.emojiToImage(fontSize: fontSize)
        }
    
        let cell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.textLabel?.text = boardBlock.title
        cell.imageView?.image = iconImage
        cell.accessoryType = self.choosedBoard.id == boardBlock.id ? .checkmark : .none
        return cell
    }
    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return UIView(frame: .zero)
//    }
        
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return CGFloat.leastNormalMagnitude
//    }
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
        case .boards(let boards):
            boardBlock = boards[indexPath.row]
        }
        self.moveToBoard(boardBlock)
    }
    
    func moveToBoard(_ boardBlock:BlockInfo) {
        if viewModel.board.id != boardBlock.id {
            viewModel.moveTo(newBoard: boardBlock)
        }
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
