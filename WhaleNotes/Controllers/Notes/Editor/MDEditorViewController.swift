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
    static let paddingH:CGFloat = 16
}
class MDEditorViewController: UIViewController {
    
    enum EditorCellNodeType {
        case title
        case content
//        case tags
    }
    
    private  var disposeBag = DisposeBag()
    var noteInfo:NoteInfo!
    private var model:NoteInfoViewModel!
    private var isNoteUpdated:Bool = false
    var cellNodeTypes:[EditorCellNodeType] = [.title,.content]
    
    private var isKeyboardShow = false
    
//    private var noteEditorEvent:NoteEditorEvent?
    private var callbackNoteInfoEdited:((NoteInfo)->Void)?
    
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
        $0.isTranslucent = false
//        $0.delegate = self
        let barAppearance =  UINavigationBarAppearance()
    //   barAppearance.configureWithDefaultBackground()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .white
            
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    
    private lazy var tableView = ASTableNode().then {
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: HomeViewController.toolbarHeight+20, right: 0)
//        $0.backgroundColor = .red
        $0.view.allowsSelection = false
        $0.view.separatorStyle = .none
        $0.view.keyboardDismissMode = .onDrag
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.registerNoteInfoEvent()
    }
    
    private func setupUI(){
        self.view.addSubview(tableView.view)
        tableView.view.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(self.topbarHeight)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        self.view.addSubview(myNavbar)
        myNavbar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor =  .white
        
        self.setupNavgationBar()
        self.registerTableViewTaped()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tryUpdateInputing()
        tryEmitUpdateEvent(isDelay: isKeyboardShow)
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    @objc func keyboardWillAppear() {
        //Do something here
        isKeyboardShow = true
    }

    @objc func keyboardWillDisappear() {
        //Do something here
        isKeyboardShow = false
    }
    
    @objc func appMovedToBackground() {
        tryUpdateInputing()
    }
    
    
    func callbackNoteInfoEdited(action: @escaping (NoteInfo) -> Void) {
        self.callbackNoteInfoEdited = action
    }
    
    func tryEmitUpdateEvent(isDelay:Bool)  {
        if isDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self  else {  return }
                
                if self.isNoteUpdated {
                   self.callbackNoteInfoEdited?(self.noteInfo)
                }
            }
            return
        }
        if self.isNoteUpdated {
            self.callbackNoteInfoEdited?(self.noteInfo)
        }
    }
}

extension MDEditorViewController {
    
    func tryUpdateInputing() {
        if !isKeyboardShow { return }
        if let titleCelleNode = self.tableView.nodeForRow(at: IndexPath(row: 0, section: 0)) as?  NoteTitleCellNode,
           titleCelleNode.titleNode.isFirstResponder()
           {
            self.updateInputTitle(titleCelleNode.title)
            return
        }
//        if let contentCelleNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode,
//           contentCelleNode.contentNode.isFirstResponder()
//           {
//            self.updateInputContent(contentCelleNode.content)
//            return
//        }
    }
//    private func tryResignResponder() {
//        if !isKeyboardShow  { return }
////            if let titleCelleNode = self.tableView.nodeForRow(at: IndexPath(row: 0, section: 0)) as?  NoteTitleCellNode
////               {
////                titleCelleNode.resignFirstResponder()
////                return
////            }
//            if let contentCelleNode = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as?  NoteContentCellNode,
//               contentCelleNode.contentNode.isFirstResponder()
//               {
//                contentCelleNode.contentNode.resignFirstResponder()
//                return
//            }
//    }
}


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
            self.noteInfo = noteInfo
        }
    }
    
}


// MARK: 处理空白区域点击
extension MDEditorViewController {
    private func registerTableViewTaped() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        tapGesture.cancelsTouchesInView = false
        self.tableView.view.addGestureRecognizer(tapGesture)
    }

    @objc func tableViewTapped(_ sender: UITapGestureRecognizer) {

        if sender.state != .ended {
            return
        }
        let touch = sender.location(in: self.tableView.view)
        if let _ = tableView.indexPathForRow(at: touch) { // 点击空白区域
            return
        }
        if let contentCell = self.tableView.nodeForRow(at: IndexPath(row: 1, section: 0)) as? NoteContentCellNode {
//            contentCell.contentNode.becomeFirstResponder()
        }
    }
}

extension MDEditorViewController {
    private func setupNavgationBar() {
        
        let navItem = UINavigationItem()
        myNavbar.items = [navItem]
        myNavbar.tintColor = .iconColor
        self.createBackBarButton(forNavigationItem: navItem)
       
        let tagButton = generateUIBarButtonItem(imageName: "tag", action:  #selector(tagIconTapped))
        
        let menuButton = generateUIBarButtonItem(imageName: "ellipsis", action:  #selector(menuIconTapped))
        navItem.rightBarButtonItems = [menuButton,tagButton]
    }
    
    func generateUIBarButtonItem(imageName:String,action:Selector)  ->  UIBarButtonItem {
        return  UIBarButtonItem(image: UIImage(systemName: imageName,pointSize: 15,weight: .regular)?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: action).then {
            $0.tintColor = .iconColor
        }
    }
    
    func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
        
        let backButtonImage =  UIImage(systemName: "chevron.left", pointSize: 20, weight: .regular)
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        backButton.leftImage(image: backButtonImage!, renderMode: .alwaysOriginal)
//        backButton.backgroundColor = .red
           backButton.addTarget(self, action: #selector(backBarButtonTapped), for: .touchUpInside)
           let backBarButton = UIBarButtonItem(customView: backButton)
           navigationItem.leftBarButtonItems = [backBarButton]
    }
    
    @objc func backBarButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func menuIconTapped() {
    }
    
    
    @objc func tagIconTapped() {
    }
}


extension MDEditorViewController:ASTableDelegate {
    
}

extension MDEditorViewController:ASTableDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellNodeTypes.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNodeType = self.cellNodeTypes[indexPath.row]
        switch cellNodeType {
        case .title:
            let titleCellNode = NoteTitleCellNode(title: self.noteInfo.note.title)
            titleCellNode.textChanged {[weak titleCellNode] (newText: String) in
                if let titleCellNode = titleCellNode {
                   self.refreshTableNode(node: titleCellNode)
                }
            }
            titleCellNode.textDidFinishEditing {[weak self] (newText: String) in
                self?.updateInputTitle(newText)
            }
            titleCellNode.textEnterkeyInput {[weak self] in
                self?.jump2ContentFirstWord()
            }
            return titleCellNode
        case .content:
            let contentCellNode = NoteContentCellNode(title: self.noteInfo.note.content)
            contentCellNode.textChanged {[weak contentCellNode] (newText: String) in
                if let contentCellNode = contentCellNode {
                   self.refreshTableNode(node: contentCellNode)
                }
            }
            contentCellNode.textDidFinishEditing {[weak self] (newText: String) in
                self?.updateInputContent(newText)
            }
            return contentCellNode
        }
    }
    
    private func updateInputContent(_ content:String) {
        if self.noteInfo.note.content == content{ return }
         self.model.updateNoteContent(content: content)
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
