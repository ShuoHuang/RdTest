//
//  String+Extension.swift
//  TableViewTest
//
//  Created by 黄朔 on 2019/3/16.
//  Copyright © 2019 Prophet. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

extension String {
    
    /// 获取当前字符串的md5加密字符串
    public var MD5String: String {
        let cStrl = cString(using: String.Encoding.utf8)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStrl, CC_LONG(strlen(cStrl!)), buffer)
        var md5String = ""
        for idx in 0...15 {
            let obcStrl = String.init(format: "%02x", buffer[idx])
            md5String.append(obcStrl)
        }
        free(buffer)
        return md5String
    }
    
    //Range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        
        let from = range.lowerBound.samePosition(in: self.utf16)
        let to = range.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from!),
                       length: utf16.distance(from: from!, to: to!))
    }
    
}
