//
//  HSImageCache.swift
//  TableViewTest
//
//  Created by 黄朔 on 2019/3/16.
//  Copyright © 2019 Prophet. All rights reserved.
//

import UIKit

typealias ImageResult = (_ image: UIImage, _ url: String) -> Void

class HSImageCache {
    
    static let shared = HSImageCache()
    // 二级缓存 之 内存缓存
    private let memeryCache: NSCache<NSString, UIImage>!
    // 二级缓存 之 磁盘缓存
    private let diskCache: DiskCache!
    /// 图片订阅者
    private var imageSubscribes: [String: [ImageResult]]!
    
    init() {
        // 简单起见，暂时使用NSCache的默认限制来实现淘汰机制
        memeryCache = NSCache<NSString, UIImage>()
        /// 设置内存缓存的数量限制
        memeryCache.countLimit = 20
        /// 设置内存缓存的数量限制
        memeryCache.totalCostLimit = 8 * 1024 * 1024
        
        diskCache = DiskCache()
        
        imageSubscribes = [:]
    }
    
    /// 直接同步获取磁盘中的图片，加载成功的话，添加到内存缓存中
    func imageInDisk(with url: String) -> UIImage? {
        if let image = memeryCache.object(forKey: url.MD5String as NSString) {
            return image
        }
        if let image = diskCache.image(with: url.MD5String) {
            memeryCache.setObject(image, forKey: url.MD5String as NSString)
            return image
        }
        downloadImage(with: url)
        return nil
    }
    
    func image(with url: String) -> UIImage? {
        // 从内存缓存中获取图片
        if let image = memeryCache.object(forKey: url.MD5String as NSString) {
            print("--从缓存中加载成功---" + url)
            return image
        } else {
            // 内存缓存中没有当前图片,则从磁盘中加载
            diskCache.asyncLoadImage(with: url) { [weak self] (image) in
                if let img = image {
                    
                    print("--从磁盘中加载成功---" + url)
                    
                    let key = url.MD5String
                    // 成功加载到图片，首先通知订阅者
                    if let callbacks = self?.imageSubscribes[key] {
                        for callback in callbacks {
                            DispatchQueue.main.async {
                                callback(img, url)
                            }
                        }
                    }
                    // 通知完订阅者后，移除当前图片的订阅者
                    self?.imageSubscribes.removeValue(forKey: key)
                    // 然后将图片加载到内存缓存中
                    self?.memeryCache.setObject(img, forKey: key as NSString)
                    
                } else {
                    // 磁盘中没有图片，则从网络下载
                    self?.downloadImage(with: url)
                }
            }
        }
        return nil
    }
    
    /// 订阅一张图片
    func subscribImage(with url: String, _ callback: @escaping ImageResult) {
        let key = url.MD5String
        var callbacks = imageSubscribes[key] ?? []
        callbacks.append(callback)
        
        imageSubscribes[key] = callbacks
    }
    
}



/// ImageCache私有方法
extension HSImageCache {
    
    /// 从网络下载图片
    /// 时间原因，采用GCD的异步方案，其实这里的逻辑使用NSOperation的方案更合适，可以更方便的控制并发数量及一些其他的状态控制
    private func downloadImage(with url: String) {
        
        if let imageURL = URL(string: url) {
            DispatchQueue.global().async { [weak self] in
                // 下载图片数据
                var imageData: Data?
                do {
                    imageData = try Data(contentsOf: imageURL, options: .mappedIfSafe)
                } catch {
                    print(error)
                }
                // 将Data转换为UIImage对象
                if let data = imageData, let image = UIImage(data: data) {
                    print("--从网络下载成功---" + url)
                    let key = url.MD5String
                    // 成功下载到图片，首先通知订阅者
                    if let callbacks = self?.imageSubscribes[key] {
                        for callback in callbacks {
                            DispatchQueue.main.async {
                                callback(image, url)
                            }
                        }
                        // 通知完订阅者后，移除当前图片的订阅者
                        self?.imageSubscribes.removeValue(forKey: key)
                    }
                    
                    // 然后将图片加载到内存缓存中
                    self?.memeryCache.setObject(image, forKey: key as NSString)
                    
                    // 然后将数据保存到磁盘中
                    self?.diskCache.saveImage(with: data, url: url)
                }
            }
        }
    }
}




/// 图片磁盘缓存
class DiskCache {
    /// 图片磁盘缓存路径
    private static let ImageSavePath = "Images"
    
    /// 保存图片到磁盘
    fileprivate func saveImage(with data: Data, url: String) {
        DispatchQueue.global().async {
            let key = url.MD5String
            
            let savePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" + DiskCache.ImageSavePath
            // 文件存储路径
            let imagePath = savePath + "/" + key
            // 检查图片保存文件夹是否存在，没有则创建
            if !FileManager.default.fileExists(atPath: savePath) {
                try! FileManager.default.createDirectory(atPath: savePath, withIntermediateDirectories: true, attributes: nil)
            }
            do {
                try data.write(to: URL(fileURLWithPath: imagePath), options: .atomic)
            } catch {
                print(error)
            }
        }
    }
    
    /// 从磁盘中异步加载图片，完事后通知图片订阅者
    fileprivate func asyncLoadImage(with url: String, _ completion: ((_ image: UIImage?) -> Void)?) {
        
        DispatchQueue.global().async { [weak self] in
            let key = url.MD5String
            
            if let callback = completion {
                callback(self?.image(with: key))
            }
        }
    }
    
    /// 从磁盘中同步加载图片
    fileprivate func image(with key: String) -> UIImage? {
        // 文件存储路径
        let imagePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" + DiskCache.ImageSavePath + "/" + key
        return UIImage(contentsOfFile: imagePath)
    }
    
}
