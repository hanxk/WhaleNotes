//
//  UITableView+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/21.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

extension UITableView {

    func scrollToBottom(){

        DispatchQueue.main.async {
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections-1) - 1,
                section: self.numberOfSections - 1)
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func scrollToTop() {

        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    
    func reloadRowsWithoutAnim(at indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            let loc = self.contentOffset
            self.reloadRows(at: indexPaths, with: .none)
            self.contentOffset = loc
        }
    }
}


extension ASTableNode {
    func reloadData(animated: Bool) {
        self.reloadData(animated: animated, completion: nil)
    }

    func reloadData(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadData()
        }, completion: completion)
    }

    func reloadSections(animated: Bool = false, sections: IndexSet, rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)? = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadSections(sections, with: rowAnimation)
        }, completion: completion)
    }

    func reloadRows(rows: [IndexPath], rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)?  = nil) {
        let animated = rowAnimation != .none
        self.performBatch(animated: animated, updates: {
            self.reloadRows(at: rows, with: rowAnimation)
        }, completion: completion)
    }
    
    func reloadRowsWithoutAnim(at indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            let loc = self.contentOffset
            self.reloadRows(at: indexPaths, with: .none)
            self.contentOffset = loc
        }
    }
}
