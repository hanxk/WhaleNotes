//
//  PopMenuController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import FloatingPanel
import SwiftMessages

class PopMenuController:UITableViewController  {
    
    var menuRows:[PopMenuRow]  = []
    
    let cellHeight:CGFloat = 54
    let contentPadding  = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    
    var rowSelected:((PopMenuRow)->Void)?
    
    convenience init(menuRows: [PopMenuRow]) {
        self.init()
        self.menuRows = menuRows
    }
    
    func showModal(vc:UIViewController) {
        let fpc = FloatingPanelController()
        let contentVC = self
//        fpc.contentMode = .fitToBounds
        
        // Create a new appearance.
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 14.0
        appearance.shadows = []
        fpc.surfaceView.appearance = appearance
        fpc.surfaceView.contentPadding = contentVC.contentPadding
        // Define shadows
        let shadow = SurfaceAppearance.Shadow()
        shadow.color = UIColor.black
        shadow.offset = CGSize(width: 0, height: 16)
        shadow.radius = 16
        shadow.spread = 8
        
//        fpc.surfaceView.cornerRadius = 12.0
        fpc.backdropView.backgroundColor = .black
        fpc.surfaceView.grabberHandle.isHidden = true
        fpc.panGestureRecognizer.isEnabled = false
//        fpc.track(scrollView: contentVC.tableView)
        fpc.isRemovalInteractionEnabled = false // Optional: Let it removable by a swipe-down
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.delegate = contentVC
        fpc.set(contentViewController: contentVC)
        
        vc.present(fpc, animated: true, completion: nil)

        
//        let segue = SwiftMessagesSegue(identifier: "123", source: vc, destination: self)
//        segue.configure(layout: .bottomCard)
//        segue.perform()
        
//        var config = SwiftMessages.defaultConfig
//        config.duration = .forever
//        SwiftMessages.show(config: config, view: fpc.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.estimatedRowHeight = 48
//        tableView.rowHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
}

extension PopMenuController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuRow = self.menuRows[indexPath.row]
        let tintColor:UIColor = menuRow.isDestroy ? .red : .cardText
        
        let cell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "").then {
            $0.textLabel?.textColor =  tintColor
            $0.textLabel?.text = menuRow.title
//            $0.contentView.backgroundColor = .cellSelectedColor
            if let menuIcon = menuRow.icon {
                $0.imageView?.image = menuIcon.withRenderingMode(.alwaysTemplate)
                $0.imageView?.tintColor = tintColor
            }
        }
        return  cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true, completion: nil)
        self.rowSelected?(self.menuRows[indexPath.row])
    }
}


class MyFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    
    
    var panelHeight:CGFloat = 0
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
//            .full: FloatingPanelLayoutAnchor(absoluteInset: panelHeight, edge: .bottom, referenceGuide: .safeArea),
//            .half: FloatingPanelLayoutAnchor(absoluteInset: panelHeight, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: panelHeight, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
    convenience init(panelHeight:CGFloat) {
        self.init()
        self.panelHeight = panelHeight
    }
    
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.2
    }
    
    
}

extension PopMenuController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let panel = MyFloatingPanelLayout(panelHeight: generatePopHeight())
        return panel
    }
    
    
    func generatePopHeight() -> CGFloat {
        return CGFloat(self.menuRows.count) * cellHeight +  contentPadding.top + contentPadding.bottom
    }
}


//fileprivate class MyFloatingPanelLayout: FloatingPanelLayout {
//    var position: FloatingPanelPosition
//
//    var initialState: FloatingPanelState
//
////    var position: FloatingPanelPosition
////
////    var initialState: FloatingPanelState
//
//    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring]
//
//    public var initialPosition: FloatingPanelPosition {
//        return .bottom
//    }
//
//    public var supportedPositions: Set<FloatingPanelPosition> {
//        return [.bottom]
//    }
//    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
//        switch position {
//        case .top: return 16.0 // A top inset from safe area
//        case .bottom: return 216.0 // A bottom inset from the safe area
////            case .tip: return 144.0 // A bottom inset from the safe area
//            default: return nil // Or `case .hidden: return nil`
//        }
//    }
//
//    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
//        return 0.1
//    }
//}
