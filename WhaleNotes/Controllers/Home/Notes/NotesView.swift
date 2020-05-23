//
//  NotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import RealmSwift
import SnapKit
import AsyncDisplayKit
import TLPhotoPicker
import RxSwift
import Photos
import ContextMenu


//protocol NotesViewDelegate: AnyObject {
//    func didSelectItemAt(note:Note,indexPath: IndexPath)
//}

class NotesView: UIView, UINavigationControllerDelegate {
    
//    weak var delegate: NotesViewDelegate?
    private lazy var disposeBag = DisposeBag()
    
    private var selectedIndexPath:IndexPath?
    
    enum NotesViewConstants {
        static let cellSpace: CGFloat = 8
        static let cellHorizontalSpace: CGFloat = 12
    }
    
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: 2, columnSpacing: 10, interItemSpacing: 10, sectionInsets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    
    
    private(set) lazy var collectionNode = ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
        guard let self = self else {return}
        $0.alwaysBounceVertical = true
        let _layoutInspector = layoutDelegate
        $0.dataSource = self
        $0.delegate = self
        $0.layoutInspector = _layoutInspector
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 160, right: 0)
        $0.showsVerticalScrollIndicator = false
        //        $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
    }
    
    
    private var notesResult:Results<Note>!
    //    private var notesClone:[NoteClone] = []
    //    private var notes:Results<Note>?
    //    private var cardsSize:[String:CGFloat] = [:]
    private var notesToken:NotificationToken?
    private var columnCount = 0
    private var cardWidth:CGFloat = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.columnCount = 2
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace*2 - NotesViewConstants.cellSpace*CGFloat(columnCount-1)
        self.cardWidth = validWidth / CGFloat(columnCount)
        self.setupUI()
        self.setupData()
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        collectionNode.frame = self.frame
        self.addSubnode(collectionNode)
        
        self.setupFloatButtons()
    }
    
    private func setupData() {
        self.notesResult = DBManager.sharedInstance.getAllNotes()
        //        self.notesToken = notesResult.observe { [weak self] (changes: RealmCollectionChange) in
        //            guard let self = self else { return }
        //            switch changes {
        //            case .initial:
        //                self.collectionNode.reloadData()
        //            case .update(_, let deletions, let insertions, let modifications):
        //                self.collectionNode.performBatchUpdates({
        //                    // 更新数据源
        //                    self.collectionNode.insertItems(at: insertions.map({ IndexPath(row: $0, section: 0)}))
        //                    self.collectionNode.deleteItems(at: deletions.map({ IndexPath(row: $0, section: 0)}))
        //                    self.collectionNode.reloadItems(at: modifications.map({ IndexPath(row: $0, section: 0)}))
        //                }, completion: nil)
        //                break
        //            case .error(let error):
        //                fatalError("\(error)")
        //            }
        //        }
    }
}

extension NotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
        print(String(self.notesResult.count))
    }
    
    
    func viewWillDisappear(_ animated: Bool) {
        //        notesToken?.invalidate()
        print(String(self.notesResult.count))
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        guard let indexPath = self.selectedIndexPath else { return }
        switch mode {
        case .insert:
            self.collectionNode.performBatchUpdates({
                self.collectionNode.insertItems(at: [indexPath])
            }, completion: nil)
        case .update:
            self.collectionNode.performBatchUpdates({
                self.collectionNode.reloadItems(at: [indexPath])
            }, completion: nil)
        case .delete:
            self.collectionNode.performBatchUpdates({
                self.collectionNode.deleteItems(at: [indexPath])
            }, completion: nil)
            break
        }
    }
}

extension NotesView {
    
    func createNote(createMode: CreateMode) -> Note{
        let note = self.generateNote(createMode: createMode)
        DBManager.sharedInstance.addNote(note)
        return note
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
}


extension NotesView: ASCollectionDataSource {
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.notesResult.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.notesResult[indexPath.row]
        
        let noteContent = NoteContent(note:note)
        return {
            return NoteCellNode(noteContent: noteContent)
        }
    }
}


extension NotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.notesResult[indexPath.row]
        self.openEditorVC(note: note)
    }
}



// float buttons
extension NotesView {
    
    func setupFloatButtons() {
        let btnNewNote = makeButton().then {
            $0.tintColor = .white
            $0.backgroundColor = .brand
            $0.setImage( UIImage(systemName: "square.and.pencil"), for: .normal)
            $0.addTarget(self, action: #selector(btnNewNoteTapped), for: .touchUpInside)
        }
        self.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(52)
            make.bottom.equalTo(self).offset(-26)
            make.trailing.equalTo(self).offset(-15)
        }
        
        let btnMore = makeButton().then {
            $0.backgroundColor = .white
            $0.tintColor = .brand
            $0.setImage( UIImage(systemName: "ellipsis"), for: .normal)
            $0.addTarget(self, action: #selector(btnMoreTapped), for: .touchUpInside)
        }
        self.addSubview(btnMore)
        btnMore.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(52)
            make.bottom.equalTo(btnNewNote.snp.top).offset(-16)
            make.trailing.equalTo(btnNewNote)
        }
    }
    
    @objc func btnNewNoteTapped (sender:UIButton) {
        //        self.openNoteEditor(createMode: .text)
        self.openEditor(createMode: .text)
        
    }
    
    private func openNoteEditor(type: MenuType) {
        switch type {
        case .text:
            self.openEditor(createMode: .text)
        case .todo:
            self.openEditor(createMode: .todo)
        case .image:
            let viewController = TLPhotosPickerViewController()
            viewController.delegate = self
            var configure = TLPhotosPickerConfigure()
            configure.allowedVideo = false
            configure.allowedLivePhotos = false
            configure.allowedVideoRecording = false
            viewController.configure = configure
            self.controller?.present(viewController, animated: true, completion: nil)
        case .camera:
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.image"]
            self.controller?.present(vc, animated: true)
            break
        }
    }
    
    func openEditor(createMode: CreateMode) {
        let note = createNote(createMode: createMode)
        openEditorVC(note:note, isNew: true)
    }
    
    func openEditorVC(note: Note,isNew:Bool = false) {
        guard let row = notesResult.firstIndex(of: note) else { return }
        self.selectedIndexPath = IndexPath(row: row, section: 0)
        
        let noteVC  = EditorViewController()
        noteVC.mode = isNew ? EditorMode.create(note: note) :  EditorMode.browser(note: note)
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
    @objc func btnMoreTapped (sender:UIButton) {
        let popMenuVC = PopBlocksViewController()
        popMenuVC.isFromHome = true
        popMenuVC.cellTapped = { [weak self] type in
            popMenuVC.dismiss(animated: true, completion: {
                self?.openNoteEditor(type:type)
            })
        }
        ContextMenu.shared.show(
            sourceViewController: self.controller!,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: sender
        )
    }
    
    private func makeButton() -> UIButton {
        let btn = UIButton()
        btn.contentMode = .center
        btn.imageView?.contentMode = .scaleAspectFit
        let layer0 = btn.layer
        layer0.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 4
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.cornerRadius = 26
        layer0.backgroundColor = UIColor(red: 0.278, green: 0.627, blue: 0.957, alpha: 1).cgColor
        return btn
    }
    
}


extension NotesView: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    func handlePicker(images: [TLPHAsset]) {
        self.controller?.showHud()
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
                self.controller?.hideHUD()
                if let blocks  = $0.element {
                    self.openEditor(createMode: .attachment(blocks: blocks))
                }
        }
        .disposed(by: disposeBag)
    }
}


extension NotesView: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {  return}
        self.handlePicker(image: image)
    }
    
    func handlePicker(image: UIImage) {
        self.controller?.showHud()
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
                self.controller?.hideHUD()
                if let blocks  = $0.element {
                    self.openEditor(createMode: .attachment(blocks: blocks))
                }
        }
        .disposed(by: disposeBag)
    }
}
