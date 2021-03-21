//
//  SearchNotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit
import AsyncDisplayKit
import TLPhotoPicker
import RxSwift
import Photos
import ContextMenu
import JXPhotoBrowser

class SearchNotesView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    private var cards:[BlockInfo] = []
    var boardMap:[String:BlockInfo] = [:]
    private var numberOfColumns = 2
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns),
                                                      columnSpacing: 0,
                                                      interItemSpacing: 0,
                                                      sectionInsets: UIEdgeInsets(top: 0, left: BoardViewConstants.waterfall_cellHorizontalSpace, bottom: BoardViewConstants.waterfall_verticalSpace, right:  BoardViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    private var mode:DisplayMode = .grid
    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
        return ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
            guard let self = self else {return}
            $0.alwaysBounceVertical = true
            let _layoutInspector = layoutDelegate
            $0.dataSource = self
            $0.delegate = self
            $0.layoutInspector = _layoutInspector
            $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: self.controller!.toolbarHeight+20, right: 0)
            $0.showsVerticalScrollIndicator = false
            
        }
    }
    private var keyword:String = ""
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    private func setupUI() {
        collectionNode.frame = self.frame
        collectionNode.backgroundColor = .bg
        self.addSubnode(collectionNode)
    }
    
    private func loadBoards() {
        BoardsRepo.shared.getBoards()
            .subscribe {[weak self] in
                self?.setupBoardsMap(boards: $0)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupBoardsMap(boards:[BlockInfo]) {
        boards.forEach {
            boardMap[$0.id] = $0
        }
    }
    
    func searchNotes(keyword:String) {
        self.keyword = keyword
        if keyword.isEmpty {
            self.cards = []
            self.collectionNode.reloadData()
            return
        }
        
        BlockRepo.shared.searchCards(keyword: keyword)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.cards = $0
                    self.collectionNode.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}


extension SearchNotesView: ASCollectionDataSource {
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        let count = self.cards.count
        if count == 0 {
            collectionNode.setEmptyMessage("暂无便签")
        }else {
            collectionNode.clearEmptyMessage()
        }
        return count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let cardBlock = self.cards[indexPath.row]
        return {
            let node =  CardCellNode(cardBlock:cardBlock)
//            node.delegate = self
            return node
        }
    }
    
}

extension SearchNotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let cardBlock = self.cards[indexPath.row]
        self.openEditorVC(card: cardBlock)
    }
    func openEditorVC(card: BlockInfo,isNew:Bool = false) {
        guard let board = boardMap[card.ownerId] else { return }
        let viewModel:CardEditorViewModel = CardEditorViewModel(blockInfo: card,board: board)
        let noteVC  = CardEditorViewController()
        noteVC.viewModel = viewModel
        noteVC.updateCallback = { [weak self] event in
            self?.handleEditorUpdateEvent(event: event)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
    func handleEditorUpdateEvent(event:EditorUpdateEvent) {
        switch event {
            case .updated(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .statusChanged(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .backgroundChanged(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .moved(block: let block, boardBlock: let boardBlock):
                self.refreshBlockCell(block: block)
                print(boardBlock.title)
                break
            case .delete(block: let block):
                self.removeCardCell(card: block)
                break
        }
    }
    
    private func refreshBlockCell(block:BlockInfo) {
        guard let index = self.cards.firstIndex(where: {$0.id == block.id}) else { return }
        self.cards[index] = block
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
            }, completion: nil)
        }
    }
    
    private func removeCardCell(card:BlockInfo) {
       guard let index = self.cards.firstIndex(where: {$0.id == card.id}) else { return }
        self.cards.remove(at: index)
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.deleteItems(at: [IndexPath(row: index, section: 0)])
            }, completion: nil)
        }
    }
}
