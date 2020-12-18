//
//  NoteColorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import FloatingPanel

class NoteColorViewController: UIViewController {
    
    private let noOfCellsInRow = 6
    
    static func openModel(sourceVC:UIViewController) {
        
        let contentVC = NoteColorViewController()
        let fpc = FloatingPanelController()
//        fpc.delegate = contentVC
//        fpc.isRemovalInteractionEnabled = true
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
//        fpc.surfaceView.cornerRadius = 8
//        fpc.surfaceView.shadowHidden = false
        fpc.track(scrollView: contentVC.collectionView)
        
        fpc.set(contentViewController: contentVC)
        sourceVC.present(fpc, animated: true, completion: nil)
    }
    
    var colors:[(String,String)] = [
        (NoteBackground.gray,"默认"),
        (NoteBackground.red,"红"),
//        (NoteBackground.orange,"橙"),
        (NoteBackground.yellow,"黄"),
        (NoteBackground.blue,"蓝"),
        (NoteBackground.green,"绿"),
//        (NoteBackground.cyan,"青"),
        (NoteBackground.purple,"紫"),
//        (NoteBackground.pink,"粉")
                        ]
    
    private let cellReuseIndetifier = "NoteColorCircleCell"
    private var cachedWidth:[String:CGFloat] = [:]
    
    var selectedColor:String = NoteBackground.gray
    var callbackColorChoosed:((String)->Void)?
    
    let flowLayout = UICollectionViewFlowLayout().then {
        let space:CGFloat = 14
        let topPadding:CGFloat = 14
        $0.minimumLineSpacing = space
        $0.minimumInteritemSpacing = space
        $0.scrollDirection = .vertical
        
        $0.sectionInset = UIEdgeInsets(top: topPadding, left:  space, bottom: topPadding+6, right:  space)
    }
    
    lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        guard let self = self else {return}
        $0.delegate = self
        $0.dataSource = self
        $0.register(NoteColorCircleCell.self, forCellWithReuseIdentifier: self.cellReuseIndetifier)
        $0.backgroundColor = .white
        $0.alwaysBounceVertical = true
    }
    
    private func setupCollectionView() {
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "背景色"
        setupCollectionView()
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
}

extension NoteColorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:cellReuseIndetifier, for: indexPath) as! NoteColorCircleCell
        cell.colorInfo = self.colors[indexPath.row]
        cell.isChecked = self.selectedColor == self.colors[indexPath.row].0
        cell.colorView.tag = indexPath.row
        cell.colorView.addTarget(self, action: #selector(handleButtonTapped), for: .touchUpInside)
        return cell
    }
    
    
    @objc func handleButtonTapped(sender: UIButton) {
        let row = sender.tag as Int
        let colorInfo = self.colors[row]
        self.callbackColorChoosed?(colorInfo.0)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
}


extension NoteColorViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        callbackColorChoosed?(self.colors[indexPath.row].0)
        print("哈哈哈2")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

      return generateItemSize()
    }
    
    func generateItemSize() -> CGSize {

        let flowLayout = self.flowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((self.view.frame.width - totalSpace) / CGFloat(noOfCellsInRow))

        return CGSize(width: size, height: size)
        
    }
    
}

//extension NoteColorViewController: FloatingPanelControllerDelegate {
//    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
//           return MyFloatingPanelLayout()
//    }
//}
//
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


//
extension NoteColorViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let height = generatePopHeight()
        let config =  BottomPresentationConfig(height: height)
        return BottomPresentationController(presentedViewController: presented, presenting: presenting,config:config)
    }

    func generatePopHeight() -> CGFloat {
        let noOfRows = 1
        let flowLayout = self.flowLayout
        let totalSpace = flowLayout.sectionInset.top + flowLayout.sectionInset.bottom
                        + (flowLayout.minimumLineSpacing * CGFloat(noOfRows - 1))

        let itemSize = self.generateItemSize()
        return  itemSize.height * CGFloat(noOfRows) + totalSpace + self.topbarHeight
    }
}
