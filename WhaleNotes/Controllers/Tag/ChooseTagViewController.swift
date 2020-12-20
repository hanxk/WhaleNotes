//
//  SearchViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import RxSwift

class ChooseTagViewController: UITableViewController {
    
    private var tags:[Tag] = []
    private let cellHeight:CGFloat = 44
    
    
//    private var selectedTags:[Tag] = []
    
    private var selectedTags:[Tag] {
        get {
            return noteInfo.tags
        }
        set {
            noteInfo.tags = newValue
        }
    }
    
    var noteInfo:NoteInfo!
    var isEdited =  false
    
    private var isSearchEmpty:Bool  {
        return tags.count==1 && tags[0].title.isEmpty
    }
    
    
    private lazy var  searchController = UISearchController(searchResultsController:  nil).then{
        $0.searchResultsUpdater = self
        $0.delegate = self
        $0.searchBar.delegate = self
        $0.searchBar.showsCancelButton = true
        $0.hidesNavigationBarDuringPresentation = false
        $0.obscuresBackgroundDuringPresentation = false
        $0.searchBar.placeholder = "查找或者创建标签"
        
        if let cancelButton = $0.searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitle("完成", for: .normal)
//            cancelButton.setTitleColor(.brand, for: .normal)
        }
    }
    
    private var disposeBag = DisposeBag()
    private var emptyTag = Tag()
    private var searchText:String  = "" {
        didSet {
            self.loadTags()
        }
    }
    var tagsChanged:((NoteInfo)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        self.setupUI()
        
//        self.selectedTags = self.noteInfo.tags
        self.loadTags()
        self.navigationController?.presentationController?.delegate = self
    }
    
    private func setupUI() {
        self.tableView.separatorStyle = .none
        self.navigationItem.titleView = searchController.searchBar
    }
    
    
    func loadTags() {
        NoteRepo.shared.searchTags(searchText)
            .subscribe(onNext: { [weak self] tags in
                if let self = self {
                    self.tags = tags
                    let isSearchEmpty = self.searchText.isNotEmpty && tags.isEmpty
                    if isSearchEmpty {
                        self.tags.append(self.emptyTag)
                    }
                    self.tableView.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isEdited {
            self.tagsChanged?(self.noteInfo)
        }
    }
}

extension ChooseTagViewController:UISearchControllerDelegate,UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        print(text)
    }
    
    
}

//MARK: SEARCH BAR
extension ChooseTagViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var newText = searchText.trimmingCharacters(in: .whitespaces)
        if let last = newText.last, last == "/" {
            newText = newText.substring(to: newText.count-1)
        }
        if let first = newText.first, first == "/" {
            if newText.count == 1 {
                newText = ""
            }else  {
                newText = newText.substring(from: 1)
            }
        }
        self.searchText = newText
    }
    
}



extension ChooseTagViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tag = self.tags[indexPath.row]
        let cell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "").then {
            var tagIcon:String = ""
            if isSearchEmpty {
                $0.textLabel?.text = "创建\"\(self.searchText)\""
                $0.imageView?.tintColor = .brand
                tagIcon = "plus"
            }else {
                $0.textLabel?.text = tag.title
                $0.imageView?.tintColor = .iconColor
                tagIcon = "grid"
            }
            let isSelected = self.selectedTags.contains{$0.id == tag.id}
            $0.accessoryType = isSelected ? .checkmark : .none
            $0.imageView?.image = UIImage(systemName: tagIcon)?.withRenderingMode(.alwaysTemplate)
            
        }
        return  cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchEmpty {//创建tag
            self.handleCreateNewTag(tagText: self.searchText)
        }else  {// 选择
            self.handleTagSelected(indexPath: indexPath)
        }
        
    }
    func handleCreateNewTag(tagText:String) {
        var tag = Tag()
        tag.title = tagText
        NoteRepo.shared.createTag(tag)
            .subscribe(onNext: { [weak self]  in
                guard let self = self else { return }
                self.searchController.searchBar.text = ""
                self.searchText =  ""
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func handleTagSelected(indexPath: IndexPath) {
        let tag = self.tags[indexPath.row]
        let isSelected = self.selectedTags.contains{$0.id == tag.id}
        if isSelected {
            self.deleteNoteTag(tag: tag, indexPath: indexPath)
        }else {
            self.createNoteTag(tag: tag, indexPath: indexPath)
        }
    }
    
    func deleteNoteTag(tag:Tag,indexPath: IndexPath) {
        NoteRepo.shared.deleteNoteTag(note: self.noteInfo.note, tagId: tag.id)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                self.updateSelectedTagDataSource(note: note, tag: tag)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func createNoteTag(tag:Tag,indexPath: IndexPath) {
        NoteRepo.shared.createNoteTag(note: self.noteInfo.note, tagId: tag.id)
            .subscribe(onNext: { [weak self] note  in
                guard let self = self else { return }
                self.updateSelectedTagDataSource(note: note, tag: tag)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    
    private func updateSelectedTagDataSource(note:Note,tag:Tag) {
        if let  index = self.selectedTags.firstIndex(where: {$0.id == tag.id}) {
            self.selectedTags.remove(at: index)
        }else {
            self.selectedTags.append(tag)
            self.selectedTags.sort{$0.title < $1.title }
        }
        self.noteInfo.note =  note
        self.isEdited = true
    }
}



extension ChooseTagViewController:UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        return true
    }
}
