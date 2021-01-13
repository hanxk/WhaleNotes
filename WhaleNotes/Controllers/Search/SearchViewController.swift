//
//  SearchViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class SearchViewController: UIViewController {
    
    private var notesView:NotesListView!
    var boardsMap:[String:BlockInfo]  = [:]
    
    var callbackOpenBoard:((_ boardBlock:BlockInfo) -> Void )?
    
    private lazy var  searchController = UISearchController(searchResultsController:  nil).then{
        $0.searchResultsUpdater = self
        $0.delegate = self
        $0.searchBar.delegate = self
        $0.searchBar.searchTextField.backgroundColor = .white
        $0.searchBar.showsCancelButton = true
        $0.hidesNavigationBarDuringPresentation = false
        $0.obscuresBackgroundDuringPresentation = false
        $0.searchBar.placeholder = "搜索"
        if let cancelButton = $0.searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitle("取消", for: .normal)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupUI() {
        self.view.backgroundColor = .bg
        
        let noteListView = NotesListView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view = noteListView
        self.notesView = noteListView
        
        self.navigationItem.titleView = searchController.searchBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
          self.searchController.searchBar.becomeFirstResponder()
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let  keyword = searchText.trimmingCharacters(in: .whitespaces)
        notesView.loadData(mode: .search(keyword: keyword))
    }
}


extension SearchViewController:UISearchControllerDelegate,UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        print(text)
    }
}


extension SearchViewController:UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        return true
    }
}
