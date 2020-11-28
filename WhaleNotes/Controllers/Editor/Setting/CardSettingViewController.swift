//
//  CardSettingViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class CardSettingViewController: UIViewController  {
    private var tableView:UITableView!
    var viewModel:CardEditorViewModel!
    var blockInfo:BlockInfo {
        return viewModel.blockInfo
    }
    var board:BlockInfo{
        return viewModel.board
    }
    
    private var formSections:[FormSection]  = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trashRow = blockInfo.block.status == .trash ? (FormTapRow(icon: "trash.slash", title: "恢复",showIndicator:false,action: {[weak self] in self?.handleTrashRestoreItemTapped()}))
        :(FormTapRow(icon: "trash", title: "移到废纸篓",showIndicator:false,action: {[weak self] in self?.handleTrashItemTapped()}))
        
        formSections =  [
            FormSection(rows: [
                FormTapRow(icon: "arrow.turn.up.right", title: "移动至", value: board.title,action: {[weak self] in self?.handleBoardTapped()}),
                FormTapRow(icon: "tag", title: "标签", value: board.title,action: {[weak self] in self?.handleBoardTapped()})
            ]),
            FormSection(rows: [
                trashRow
            ])
        ]
        
        self.setupUI()
        self.setupNav()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    private func setupUI() {
        
        self.title = "操作"
        
        tableView = UITableView(frame: .zero, style: .grouped).then { tableView in
            tableView.delegate = self
            tableView.dataSource = self
            tableView.estimatedRowHeight = 44
            tableView.rowHeight = UITableView.automaticDimension
            tableView.backgroundColor = .bg
            
            formSections.forEach {section in
                section.rows.forEach { row in
                    tableView.register(row.cellClass, forCellReuseIdentifier: row.identifier)
                }
            }
        }
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            $0.bottom.equalTo(view.snp.bottom)
        }
        
    }
    
    private func setupNav() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(doneButtonTapped))
    }
    
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}


//MARK: menu callback
extension CardSettingViewController {
    func handleBoardTapped() {
        let choosedBoardVC = ChangeBoardViewController()
        choosedBoardVC.viewModel = self.viewModel
        self.navigationController?.pushViewController(choosedBoardVC, animated: true)
    }
    
    func handleTrashItemTapped() {
        self.viewModel.move2Trash()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleTrashRestoreItemTapped() {
        self.viewModel.moveOutTrash()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension CardSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = self.formSections[indexPath.section].rows[indexPath.row]
        if let tapRow = row as? FormTapRow {
            tapRow.action?()
        }
    }
}
extension CardSettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return formSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formSections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return formSections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formSection = self.formSections[indexPath.section]
        let formRow = formSection.rows[indexPath.row]
        return setupCell(formRow: formRow)
    }
    
    func setupCell(formRow:FormRow)-> UITableViewCell {
        
        if let formInputRow =  formRow as? FormInputRow{
            let cell = tableView.dequeueReusableCell(withIdentifier: formRow.identifier)!
            let inputCell = cell as! FormInputCell
            inputCell.placeHolder = formInputRow.placeHolder
            inputCell.maxLines = formInputRow.maxLines
            inputCell.textChanged = { [weak self,weak formInputRow] text in
                self?.updateHeightOfRow(inputCell)
                formInputRow?.textChanged?(text)
            }
            return cell
        }
        
        if let formCommonRow =  formRow as? FormTapRow{
            let cell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: formRow.identifier).then {
                $0.textLabel?.text = formCommonRow.title
                $0.imageView?.image = UIImage(systemName: formCommonRow.icon)?.withRenderingMode(.alwaysTemplate)
                $0.imageView?.tintColor = .iconColor
                $0.accessoryType = formCommonRow.showIndicator ? .disclosureIndicator : .none
                $0.detailTextLabel?.text = formCommonRow.value
            }
            return cell
        }
        
        return UITableViewCell()
    }
    func updateHeightOfRow(_ cell: FormInputCell) {
        let size = cell.textView.bounds.size
         let newSize = tableView.sizeThatFits(CGSize(width: size.width,
                                                         height: CGFloat.greatestFiniteMagnitude))
         if size.height != newSize.height {
             UIView.setAnimationsEnabled(false)
             tableView?.beginUpdates()
             tableView?.endUpdates()
             UIView.setAnimationsEnabled(true)
             if let thisIndexPath = tableView.indexPath(for: cell) {
                 tableView.scrollToRow(at: thisIndexPath, at: .bottom, animated: false)
             }
         }
     }
    struct FormSection {
        var title:String = ""
        var rows:[FormRow]  = []
    }
    open class FormRow {
        var identifier:String {
            return String(describing: self)
        }
        open var cellClass:AnyClass {
            return FormRow.self
        }
    }
    class FormTapRow:FormRow {
        var icon:String = ""
        var title:String = ""
        var value:String = ""
        var action:(()-> Void)? = nil
        var showIndicator = false
        
        convenience init(icon:String = "",title:String = "",value:String = "",showIndicator:Bool = true,action:(()-> Void)? = nil) {
            self.init()
            self.icon = icon
            self.value = value
            self.title = title
            self.action  = action
            self.showIndicator = showIndicator
        }
        
        override var cellClass:AnyClass {
            return UITableViewCell.self
        }
    }
    class FormInputRow:FormRow  {
        var placeHolder:String = ""
        var value:String = ""
        var maxLines:Int =  1
        var textChanged:((String)-> Void)? = nil
        
        convenience init(placeHol:String = "",value:String = "",maxLines:Int =  1,textChanged:((String)-> Void)? = nil) {
            self.init()
            self.value = value
            self.maxLines = maxLines
            self.textChanged = textChanged
        }
        
        override var cellClass:AnyClass {
            return FormInputCell.self
        }
    }
    
    enum FormCellStyle {
        case input(placeHolder:String = "",textColor:UIColor?=nil,maxLines:Int = 1)
        case icon_title(icon:String = "",title:String,value:String? = nil,action:Selector? = nil)
    }
    
}



extension CardSettingViewController:UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
//        if  self.isPreventChild {
//            return false
//        }
//        if isBoardEdited {
//            self.showDismissSheet()
//            return false
//        }
        return true
    }
}

