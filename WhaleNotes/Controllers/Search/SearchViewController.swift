//
//  SearchViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class SearchViewController: UIViewController {
  
    private lazy var notesView:SearchNotesView = SearchNotesView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)).then {_ in
        print("")
//        $0.callbackCellBoardButtonTapped = { note,board in
//            self.callbackOpenBoard?(board)
//            self.dismiss(animated: true, completion: nil)
//        }
//        $0.callbackNoteEdited = { editorMode in
//            self.callbackNoteEdited(editorMode)
//        }
    }
    var boards:[BlockInfo]  = []
    
    var callbackOpenBoard:((_ boardBlock:BlockInfo) -> Void )?
    
    private lazy var searchBar = UISearchBar().then {
        $0.showsCancelButton = true
        $0.delegate = self
        $0.searchTextField.placeholder = "搜索"
        
        if let cancelButton = $0.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitle("取消", for: .normal)
            cancelButton.setTitleColor(.brand, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.titleView = searchBar
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = UIColor.bg.withAlphaComponent(0.6)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.navigationItem.titleView = UIView()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .bg
        self.view = notesView
//        self.extendedLayoutIncludesOpaqueBars = true
//        notesView.snp.makeConstraints { make in
//           make.top.equalToSuperview()
//           make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
//           make.leading.trailing.equalToSuperview()
//        }
        notesView.boardMap = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })
        searchBar.searchTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
//
extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.searchTextField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        notesView.searchNotes(keyword: searchText.trimmingCharacters(in: .whitespaces))
    }
    
}

