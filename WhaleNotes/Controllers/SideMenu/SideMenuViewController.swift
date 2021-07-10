//
//  SideMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift
import SideMenu
import DeepDiff

enum SideMenuCellContants {
    static let iconWidth:CGFloat = 24
    static let cellPadding = 20
    static let highlightColor =  UIColor(hexString: "#EFEFEF")
    
    static let selectedPadding = 10
    static  let titlePaddingRight = 8
}

protocol SideMenuViewControllerDelegate: AnyObject {
    func sideMenuItemSelected(sideMenuItem:SystemMenuItem)
    func sideMenuItemSelected(tag:Tag)
}

enum SideMenuItem:Equatable {
    case system(sysMenuItem:SystemMenuItem)
    case tag(id:String)
    
    static func == (lhs: SideMenuItem, rhs: SideMenuItem) -> Bool {
        switch (lhs,rhs)  {
        case (.system(let lmenu),.system(let rmenu) ):
            return  lmenu == rmenu
        case (.system,.tag):
            return false
        case (.tag(let lTagId) ,.tag(let rTagId)):
            return lTagId == rTagId
        case (.tag, .system):
            return false
        }
    }
}

enum SystemMenuItem:Equatable {
    case all(icon:String="doc.text",title:String="笔记")
    case trash(icon:String="trash",title:String="废纸篓")
    
    var title:String {
        switch self {
        case .all(_,let title):
            return title
        case .trash(_,let title):
            return title
        }
    }
    var icon:String {
        switch self {
        case .all(let icon,_):
            return icon
        case .trash(let icon,_):
            return icon
        }
    }
    
    static func == (lhs: SystemMenuItem, rhs: SystemMenuItem) -> Bool {
        return lhs.title == rhs.title
    }
    
    var index:Int{
        switch self {
        case .all:
            return 0
        default:
            return 1
        }
    }
}

enum SyetemMenuType {
    case all
    case trash
}

enum SectionItem:Int {
    case system = 0
    case tag = 1
    
    var cellIdentifier:String {
        switch self {
        case .system:
            return "system"
        case .tag:
            return "tag"
        }
    }
}

class SideMenuViewController: UIViewController {
    private let disposeBag = DisposeBag()
    weak var delegate:SideMenuViewControllerDelegate? = nil {
        didSet {
            self.selectedMenu = SideMenuItem.system(sysMenuItem:self.sysMenuItems[0])
            self.delegate?.sideMenuItemSelected(sideMenuItem: self.sysMenuItems[0])
            self.setupData(tags: [])
            self.registerEvent()
        }
    }
    
    var notification:Notification?
    var needLoadTags = true
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.separatorColor = .clear
        $0.separatorColor = .clear
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        $0.register(SideMenuCell.self, forCellReuseIdentifier:"SideMenuCell")
        
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight  = 44
        $0.showsVerticalScrollIndicator = false
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        $0.backgroundColor = .clear
        $0.dragInteractionEnabled = true
    }
    
    var tags:[Tag]  = [] {
        didSet {
            self.setupDataSource()
        }
    }
    
    enum Constants {
        static let all = SystemMenuItem.all(icon: "doc.text", title: "笔记")
        static let trash = SystemMenuItem.trash(icon: "trash", title: "废纸篓")
    }
    
    func setupDataSource() {
        self.tagsMap = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0)})
        self.tagChildCountMap = Dictionary(uniqueKeysWithValues:
                                            tagsMap.map { key, value in (key, getChildCount(tag: value)) })
        self.visibleTagIds = self.getVisibleTagIds()
    }
    
    var tagsMap:[String:Tag] = [:]
    var tagChildCountMap:[String:Int] = [:]
    
    var sectionItems:[SectionItem] =  []
    
    // 控制列表展示
    var sysMenuItems:[SystemMenuItem] = [Constants.all,Constants.trash]
    var visibleTagIds:[String] = []
    
    var selectedMenu:SideMenuItem!
    var updatedSelectedMenu:SideMenuItem? = nil
    
    func getVisibleTagIds() -> [String] {
        var expandTags:[String] = []
        findExpandTag(expandTags: &expandTags, index: 0)
        return  expandTags
    }
    
    
    func setSelectedIndexPath(_ indexPath:IndexPath,isPreventClose:Bool=false,checkSame:Bool = true) {
        if  !isPreventClose {
            SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: nil)
        }
        let sectionType =  self.sectionItems[indexPath.section]
        switch sectionType {
        case .system:
            let sysMenuItem = self.sysMenuItems[indexPath.row]
            self.selectedMenu = SideMenuItem.system(sysMenuItem:sysMenuItem )
            self.delegate?.sideMenuItemSelected(sideMenuItem: sysMenuItem)
        case  .tag:
            let tag = self.getTag(index: indexPath.row)
            self.selectedMenu = SideMenuItem.tag(id: tag.id)
            self.delegate?.sideMenuItemSelected(tag: tag)
        }
        
    }
    
    func getSelectedIndexPath() -> IndexPath? {
        guard let selectedMenu = self.selectedMenu else { return nil }
        switch selectedMenu {
        case .system(let sysMenuItem):
            return IndexPath(row: sysMenuItem.index, section: 0)
        case .tag(let id):
            if let row = self.visibleTagIds.firstIndex(of: id) {
                return IndexPath(row: row, section: 1)
            }
            return nil
        }
    }
    
    
    func getSelectedTag() -> Tag? {
        guard let selectedMenu = self.selectedMenu else { return nil }
        switch selectedMenu {
        case .system(_):
            return nil
        case .tag(let id):
            return tagsMap[id]
        }
    }
    
    func getTag(index:Int) -> Tag {
        return self.tagsMap[self.visibleTagIds[index]]!
    }
    
    static func generateCellSelectedView() ->UIView {
        return UIView().then {
            $0.backgroundColor = .sidemenuSelectedBg
            let cornerRadius:CGFloat = 8
            $0.layer.smoothCornerRadius = CGFloat(cornerRadius)
            $0.clipsToBounds = true
            $0.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let _ = self.notification else {
            if needLoadTags {
                self.refreshTags()
            }
            return
        }
        self.notification = nil
        if self.needLoadTags {
            self.needLoadTags = false
            self.loadTags { [weak self]newTags in
                guard let self = self else { return }
                self.reloadTagList(newTags: newTags,withAnim: false)
                self.updateSelected()
            }
            return
        }
        if self.updatedSelectedMenu != nil {
            self.updateSelected()
        }
//        switch notification.name {
//        case .Tag_UPDATED,.Tag_DELETED:
//            self.refreshTags()
//        case .Tag_CHANGED:
//            if let tag = notification.object as? Tag  {
//                handleTagChanged(tag)
//            }
//        default:break
//
//        }
    }
    
    private func updateSelected() {
        var updatedRows:[IndexPath] = []
        if let oldSelectedIndexPath = getSelectedIndexPath() {
            updatedRows.append(oldSelectedIndexPath)
        }
        if let updatedSelectedMenu = self.updatedSelectedMenu
           {
            self.selectedMenu = updatedSelectedMenu
            self.updatedSelectedMenu = nil
            if let newSelectedIndexPath = getSelectedIndexPath() {
                updatedRows.append(newSelectedIndexPath)
            }
        }
        if updatedRows.count > 0 {
            self.tableView.reloadRows(at: updatedRows, with: .none)
        }
    }
    
    private func refreshTags() {
        self.needLoadTags = false
        self.loadTags { [weak self]newTags in
            guard let self = self else { return }
            self.reloadTagList(newTags: newTags,withAnim: false)
        }
    }
    
    
    func reloadTagList(newTags:[Tag],withAnim:Bool = true,filterTags:[String] = [],complete:(()->(Void))? = nil) {
        let oldTags = self.tags
        if diff(old:oldTags, new: newTags).count == 0 { return }
        
        let oldVisibleTags = self.visibleTagIds.map {self.tagsMap[$0]!}
        self.tags = newTags
        let newVisibleTags = self.visibleTagIds.map {self.tagsMap[$0]!}
        
        var changes = diff(old:oldVisibleTags, new: newVisibleTags)
        if filterTags.count > 0 {
            changes = changes.filter({
                switch($0) {
                case .insert(_),
                     .delete(_),.move(_):
                    return true
                case .replace(let tagRep):
                    return !filterTags.contains(tagRep.newItem.id)
                }
            })
        }
        
        if changes.count == 0 { return }
        
        func reloadDatasource() {
            self.tableView.reload(changes: changes,section: SectionItem.tag.rawValue, updateData: {
                //                self.tags = newTags
                complete?()
            })
        }
        
        if withAnim {
            reloadDatasource()
            return
        }
        
        UIView.performWithoutAnimation {
            reloadDatasource()
        }
    }
    
    func  isTagExpand(tagTitle:String)-> Bool {
        return TagExpandCache.shared.get(key: tagTitle) != nil
    }
    
    private func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.backgroundColor = .sidemenuBg
    }
    
    private func loadTags(callback:@escaping ([Tag])->Void) {
        NoteRepo.shared.getValidTags()
            .subscribe(onNext: { tags in
                callback(tags)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupData(tags:[Tag]) {
        self.tags = tags
        
        self.sectionItems = [
            SectionItem.system,
            SectionItem.tag,
        ]
        
        self.tableView.reloadData()
    }
    
    
    deinit {
        self.unRegisterEvent()
    }
    
    private func getChildCount(tag:Tag)->Int {
        return self.tagsMap.filter{ $0.value.title.starts(with: tag.title+"/") }.count
    }
}

//MARK: Event
extension SideMenuViewController {
    private func registerEvent() {
        EventManager.shared.addObserver(observer: self, selector: #selector(handleTagChangedNotifi), name: .Tag_UPDATED)
        EventManager.shared.addObserver(observer: self, selector: #selector(handleTagChangedNotifi), name: .Tag_DELETED)
        EventManager.shared.addObserver(observer: self, selector: #selector(handleTagChangedNotifi), name: .Tag_CHANGED)
        EventManager.shared.addObserver(observer: self, selector: #selector(handleRemoteDataChanged), name: .REMOTE_DATA_CHANGED)
    }
    
    private func unRegisterEvent() {
        EventManager.shared.removeObserver(observer: self)
    }
    
    @objc private func handleTagChangedNotifi(notification: Notification) {
        logi("tag changed")
        self.notification = notification
        switch notification.name {
        case .Tag_UPDATED:
            self.needLoadTags = true
            if let tag = notification.object as? Tag {
                self.delegate?.sideMenuItemSelected(tag: tag)
                self.updatedSelectedMenu = SideMenuItem.tag(id: tag.id)
            }
            break
        case .Tag_DELETED:
            self.needLoadTags = true
            self.delegate?.sideMenuItemSelected(sideMenuItem: Constants.all)
            self.updatedSelectedMenu = SideMenuItem.system(sysMenuItem: Constants.all)
        case .Tag_CHANGED:
            guard let tag = notification.object as? Tag else { return }
            let updatedTitles = self.expandTagSource(tag)
            self.delegate?.sideMenuItemSelected(tag: tag)
            self.updatedSelectedMenu = SideMenuItem.tag(id: tag.id)
            if updatedTitles.count > 0 {
                self.needLoadTags = true
            }
            break
        default:
            break
        }
    }
    
    
    private func handleTagExpand2(tag:Tag) {
        guard let index = self.visibleTagIds.firstIndex(where: {$0 == tag.id}) else {  return }
        
        // 处理数据源
        let childIds = findExpandTagByTag(rootTagId: tag.id)
        
        let childCount = childIds.count
        if childCount  == 0 { return }
        
        let start  = index + 1
        self.visibleTagIds.insert(contentsOf: childIds, at: start)
        
        var insertIndexs:[IndexPath] = []
        for childIndex in (0...childCount-1) {
            let row = start + childIndex
            insertIndexs.append(IndexPath(row: row, section: 1))
        }
        
        self.tableView.performBatchUpdates({
            self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: index, section: 1)])
            self.tableView.insertRows(at: insertIndexs, with: .none)
        })
    }
    
    @objc private func handleRemoteDataChanged(notification: Notification) {
        self.notification = notification
    }
    
}

extension SideMenuViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionItems[section] {
        case .system:
            return self.sysMenuItems.count
        case .tag:
            return self.visibleTagIds.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > 0 {
            return 24
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath) as! SideMenuCell
        let sectionType =  self.sectionItems[indexPath.section]
        switch sectionType {
        case .system:
            cell.bindSysMenuItem(self.sysMenuItems[indexPath.row])
        case  .tag:
            let tag = getTag(index: indexPath.row)
            let childCount = self.tagChildCountMap[tag.id] ?? 0
            cell.bindTag(tag, childCount:childCount, isExpand: isTagExpand(tagTitle: tag.title))
            cell.arrowButtonTapAction  = {
                self.toggleTagExpand(tagId: tag.id)
            }
        }
        cell.cellIsSelected = getSelectedIndexPath() == indexPath
        return cell
    }
    
    
}

//MARK: 折叠展开
extension SideMenuViewController {
    
    private func toggleTagExpand(tagId:String) {
        guard let tag = self.tagsMap[tagId] else{ return }
        var newTags:[Tag] = self.tags
        var isNeedRedirect = false
        if tag.isExpand { // 折叠
            let collaspTitles = self.collaspTagSource(tag)
            
            for i in 0..<newTags.count {
                if collaspTitles.contains(newTags[i].title) {
                    newTags[i].isExpand = false
                }
            }
            if let selectedTag = getSelectedTag() {
                isNeedRedirect = selectedTag.title.starts(with: tag.title+"/")
            }
        }else {
            let expandedTitles = self.expandTagSource(tag)
            for i in 0..<newTags.count {
                if expandedTitles.contains(newTags[i].title) {
                    newTags[i].isExpand = true
                }
            }
        }
        
        if let row = self.visibleTagIds.firstIndex(of: tagId)
        {
            if isNeedRedirect {
                self.setSelected(tagId: tagId)
            }
            self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: row, section: SectionItem.tag.rawValue)])
        }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.reloadTagList(newTags: newTags,filterTags: [tagId])
        }
    }
    
    private func expandTagSource(_ tag:Tag) -> [String] {
        // 只更新数据源
        let tagTitle = tag.title
        let tagTitles = tagTitle.split("/")
        
        var updatedTitles:[String] = []
        
        var tempTitle = ""
        for title in tagTitles {
            if tempTitle.isEmpty {
                tempTitle = title
            }else {
                tempTitle = tempTitle + "/"+title
            }
            if TagExpandCache.shared.get(key: tempTitle) == nil {
               TagExpandCache.shared.set(key: tempTitle, value: tempTitle)
                updatedTitles.append(tempTitle)
            }
        }
        return updatedTitles
    }
    
    private func collaspTagSource(_ tag:Tag) -> [String] {
        // 只更新数据源
        var updatedTitles:[String] = []
        let tagTitle = tag.title
        TagExpandCache.shared.remove(key: tagTitle)
        updatedTitles.append(tagTitle)
        return updatedTitles
    }
    
    
    
    private func expandTag(tag:Tag) {
        guard let currentIndex = self.visibleTagIds.firstIndex(where: {$0 == tag.id}) else {  return }
        
        //找到根结点是否展开
        let tagTitle = tag.title
        let tagTitles = tagTitle.split("/")
        
        var insertIndexs:[IndexPath] = []
        
        var tempTitle = ""
        for title in tagTitles {
            
            if tempTitle.isEmpty {
                tempTitle = title
            }else {
                tempTitle = tempTitle + "/"+title
            }
            
            guard let tag = self.tags.first(where: {$0.title == tempTitle}) else { return }
            let tagId = tag.id
            if TagExpandCache.shared.get(key: tagId) != nil { // 已经展开
                continue
            }
            guard let index = self.visibleTagIds.firstIndex(where: {$0 == tagId}) else {  return }
            
            let childIds = findExpandTagByTag(rootTagId: tagId)
            let childCount = childIds.count
            if childCount  == 0 { return }
            
            let start  = index + 1
            self.visibleTagIds.insert(contentsOf: childIds, at: start)
            TagExpandCache.shared.set(key: tag.id, value: tag.id)
            
            
            for childIndex in (0...childCount-1) {
                let row = start + childIndex
                insertIndexs.append(IndexPath(row: row, section: 1))
            }
            
            if tempTitle == tag.title {
                break
            }
        }
        
        if insertIndexs.isEmpty { return }
        
        self.tableView.performBatchUpdates({
            self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: currentIndex, section: 1)])
            self.tableView.insertRows(at: insertIndexs, with: .none)
        })
    }
    
    private func collaspTag(tagId:String) {
        guard let index = self.visibleTagIds.firstIndex(where: {$0 == tagId}) else {  return }
        let childCount = self.findVisibleChildTags(tagId: tagId).count
        
        var delIndexs:[IndexPath] = []
        let start  = index + 1
        for childIndex in (0...childCount-1) {
            let row = start + childIndex
            delIndexs.append(IndexPath(row: row, section: 1))
        }
        
        let rootIndexPath = IndexPath(row: index, section: 1)
        
        // 如果当前要折叠节点的子节点时选中状态，那么需要将当前节点更新为选中状态
        if let selectedIndexPath = getSelectedIndexPath(),delIndexs.contains(selectedIndexPath) {
            setSelectedIndexPath(rootIndexPath, isPreventClose: true)
        }
        
        TagExpandCache.shared.remove(key: tagId)
        
        self.visibleTagIds.removeSubrange(start..<(start+childCount))
        self.tableView.performBatchUpdates({
            self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: index, section: 1)])
            self.tableView.deleteRows(at: delIndexs, with: .none)
        })
    }
    
    
    
    private func findVisibleChildTags(tagId:String) -> [String] {
        let childCount = tagChildCountMap[tagId]
        if childCount   == 0 {
            return  []
        }
        let tag = tagsMap[tagId]!
        return self.visibleTagIds.filter{self.tagsMap[$0]?.title.starts(with: tag.title+"/") ?? false}
    }
    
    private func findExpandTagByTag(rootTagId:String)-> [String] {
        
        var expandTags:[String] =  []
        let childCount = tagChildCountMap[rootTagId]
        if childCount == 0 {
            return expandTags
        }
        
        guard let index =  self.tags.firstIndex(where: {$0.id == rootTagId})  else  { return []}
        
        let rootTitle = self.tags[index].title
        var start =  index+1
        
        while start  <  self.tags.count  {
            let tag = self.tags[start]
            if !tag.title.starts(with: rootTitle+"/"){ //root
                break
            }
            expandTags.append(tag.id)
            let  childCount  = self.tagChildCountMap[tag.id] ?? 0
            if !isTagExpand(tagTitle: tag.title) &&  childCount >  0  {  //  已折叠,跳过这个节点 下的子节点
                start += childCount
            }
            start += 1
        }
        return expandTags
    }
    
    private func findExpandTag(expandTags:inout [String],index:Int) {
        if index  > self.tags.count -  1 { return}
        let tag = self.tags[index]
        let tagId =  self.tags[index].id
        let childCount = tagChildCountMap[tagId] ??  0
        
        expandTags.append(tagId)
        if childCount == 0{
            return findExpandTag(expandTags: &expandTags, index: index+1)
        }
        if !isTagExpand(tagTitle: tag.title) {  //  已折叠
            return findExpandTag(expandTags: &expandTags, index: index+1+childCount)
        }
        
        let rootTitle =  self.tags[index].title
        
        var start =  index+1
        for i in (start...(self.tags.count-1)){
            let tag = self.tags[i]
            
            if !tag.title.starts(with: rootTitle+"/"){ //root
                break
            }
            let childCount = tagChildCountMap[tagId] ?? 0
            if childCount>0 { //root
                break
            }
            expandTags.append(tag.id)
            start += 1
        }
        findExpandTag(expandTags:&expandTags,index: start)
    }
    
}


extension SideMenuViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.setSelected(indexPath: indexPath)
    }
    private func setSelected(indexPath: IndexPath)   {
        var reloadRows:[IndexPath] = [indexPath]
        if let oldIndexPath = getSelectedIndexPath() {
            reloadRows.append(oldIndexPath)
        }
        self.setSelectedIndexPath(indexPath)
        self.tableView.reloadRowsWithoutAnim(at: reloadRows)
    }
    
    private func setSelected(tagId: String){
        guard let row = self.visibleTagIds.firstIndex(of: tagId) else { return }
        self.selectedMenu = SideMenuItem.tag(id: tagId)
        self.setSelectedIndexPath(IndexPath(row: row, section: SectionItem.tag.rawValue),isPreventClose: true)
    }
    
}
