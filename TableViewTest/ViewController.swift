//
//  ViewController.swift
//  TableViewTest
//
//  Created by 黄朔 on 2019/3/16.
//  Copyright © 2019 Prophet. All rights reserved.
//

import UIKit
import ZhuoZhuo

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [ResponseModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        loadData()
    }
    
    /// 加载数据，并预先计算cell高度
    /// 当图片不在本地时，以ResponseModel的图片尺寸为准，当存在时，以真实图片的尺寸为准
    func loadData() {
        // 异步处理数据，这里可以给用户转个圈
        DispatchQueue.global().async { [weak self] in
            let ds = RdTestGetResource__NotAllowedInMainThread()
            for model in ds ?? [] {
                if HSImageCache.shared.imageInDisk(with: model.imageUrl) == nil {
                    // 如果图片不存在，向HSImageCache订阅这张图片
                    self?.subscribImage(withUrl: model.imageUrl)
                }
                model.createShowData()
            }
            DispatchQueue.main.async {
                self?.dataSource = ds!
            }
        }
    }
    
    func subscribImage(withUrl url: String) {
        HSImageCache.shared.subscribImage(with: url) { [weak self] (image, url) in
            
            if let ds = self?.dataSource, let index = ds.lastIndex(where: {  $0.imageUrl == url }) {
                let model = ds[index]
                model.updateAttributedString(withImage: image, {
                    self?.tableView.beginUpdates()
                    self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self?.tableView.endUpdates()
                })
            }
        }
    }
    
}

/// ---- UITableViewDataSource, UITableViewDelegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath) as! TestCell
        cell.data = dataSource[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return dataSource[indexPath.row].attributedStringHeight + CGFloat(TestCell.OtherViewHeight)
    }
}

/// ---- TestCell
class TestCell: UITableViewCell, UITextViewDelegate {
    
    static let ContextViewWidth = UIScreen.main.bounds.width - (15 * 2)
    static let OtherViewHeight = 49
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contextView: UITextView!
    // 点击回调
    var clickCallback: ((_ url: String) -> Void)?
    
    var imageSizeChanged: ((_ data: ResponseModel, _ newImage: UIImage) -> Void)?
    
    var data: ResponseModel! {
        didSet {
            titleLabel.text = data.title
            if let string = data.attributedString {
                contextView.attributedText = string
            } else {
                contextView.text = data.context
            }
        }
    }

}
