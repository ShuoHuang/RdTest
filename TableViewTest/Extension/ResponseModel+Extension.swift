//
//  ResponseModel+Extension.swift
//  TableViewTest
//
//  Created by 黄朔 on 2019/3/16.
//  Copyright © 2019 Prophet. All rights reserved.
//

import Foundation
import UIKit
import ZhuoZhuo

private var kAttributedStringHeight = "kAttributedStringHeight"
private var kAttrString = "kAttrString"
private var kImageAtta = "kImageAtta"

extension ResponseModel {
    
    open var attributedStringHeight: CGFloat! {
        get {
            return objc_getAssociatedObject(self, &kAttributedStringHeight) as? CGFloat ?? 0
        }
        set(newValue) {
            objc_setAssociatedObject(self, &kAttributedStringHeight, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open var attributedString: NSMutableAttributedString? {
        get {
            return objc_getAssociatedObject(self, &kAttrString) as? NSMutableAttributedString
        }
        set(newValue) {
            objc_setAssociatedObject(self, &kAttrString, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open var imageAttachment: NSTextAttachment? {
        get {
            return objc_getAssociatedObject(self, &kImageAtta) as? NSTextAttachment
        }
        set(newValue) {
            objc_setAssociatedObject(self, &kImageAtta, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func createShowData() {
        if context.count == 0 &&
            (imageUrl.count == 0 || imageSizeInfo.width == 0 || imageSizeInfo.height == 0) {
            
            return
        }
        
        let attrStr = NSMutableAttributedString(string: context)
        attrStr.setAttributes([.font: UIFont.systemFont(ofSize: 17)], range: NSRange(location: 0, length: context.count))
        // 处理图片
        if imageUrl.count > 0 && imageSizeInfo.width > 0 && imageSizeInfo.height > 0 {
            imageAttachment = NSTextAttachment()
            let image = HSImageCache.shared.imageInDisk(with: imageUrl)
            imageAttachment!.image = image
            var imageHeight = CGFloat(TestCell.ContextViewWidth) * CGFloat(imageSizeInfo.height) / CGFloat(imageSizeInfo.width)
            if let img = image {
                imageHeight = CGFloat(TestCell.ContextViewWidth) * CGFloat(img.size.height) / CGFloat(img.size.width)
            } else {
                imageAttachment!.image = UIImage.createImage(with: UIColor.lightGray.withAlphaComponent(0.3))
            }
            imageAttachment!.bounds = CGRect(x: 0, y: 0, width: Int(TestCell.ContextViewWidth), height: Int(imageHeight))
            attrStr.insert(NSAttributedString(attachment: imageAttachment!), at: 0)
        }
        
        // 处理文字点击
        for clickInfo in clickInfoList {
            
            if let clickRange = context.range(of: clickInfo.targetString) {
                var nsRange = context.nsRange(from: clickRange)
                // 如果存在图片，需要偏移1位
                if let _ = imageAttachment {
                    nsRange = NSRange(location: nsRange.location + 1, length: nsRange.length + 1)
                }
                attrStr.addAttribute(.foregroundColor, value: UIColor.blue, range: nsRange)
                if clickInfo.url.count > 0 {
                    attrStr.addAttribute(.link, value: clickInfo.url, range: nsRange)
                }
            }
        }
        
        attributedString = attrStr
        attributedStringHeight = attributedString!.boundingRect(with: CGSize(width: TestCell.ContextViewWidth, height: 0),
                                                                 options: .usesLineFragmentOrigin,
                                                                 context: nil).size.height
    }
 
    func updateAttributedString(withImage image: UIImage, _ completion: @escaping () -> Void) {
        
        if let imageAttachment = self.imageAttachment {
            imageAttachment.image = image
            let newImageHeight = CGFloat(TestCell.ContextViewWidth) * CGFloat(image.size.height) / CGFloat(image.size.width)
            
            if imageAttachment.bounds.height != newImageHeight {
                imageAttachment.bounds = CGRect(x: 0, y: 0, width: TestCell.ContextViewWidth, height: newImageHeight)
                
                DispatchQueue.global().async { [weak self] in
                    let attrStrHeight = self?.attributedString?.boundingRect(with: CGSize(width: TestCell.ContextViewWidth, height: 0),
                                                                       options: .usesLineFragmentOrigin,
                                                                       context: nil).size.height
                    self?.attributedStringHeight = attrStrHeight
                    DispatchQueue.main.async {
                        completion()
                    }
                }
                
            } else {
                completion()
            }
        }
    }
    
}
