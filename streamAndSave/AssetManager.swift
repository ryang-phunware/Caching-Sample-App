//
//  AssetManager.swift
//  streamAndSave
//
//  Created by Rongbo Yang on 12/27/16.
//  Copyright © 2016 Rongbo Yang. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

enum selectedCache {
    case YYCache
    case PINCache
}

class AssetManager: NSObject, CanSaveAVAsset {
    
    //MARK: - singleton
    static let sharedInstance = AssetManager()
    
    //MARK: - Properties
    var assetCache: PWCache!
    var pinCache: PINCache!
    
    var selectedCache: selectedCache = .YYCache {
        didSet {
            print("Current selected cache is \(selectedCache)")
            printCacheSize()
        }
    }
    
    //MARK: - Init
    override init() {
        super.init()
        self.assetCache = PWCache(name: "com.Phunware.Advertising.PWAssetManager")
        self.pinCache = PINCache(name: "PINCache")
    }
    
    //MARK: - Cache Operation
    func containsObject(forKey key: String) -> Bool {
        //return false
        
        switch selectedCache {
        case .YYCache:
            return assetCache.diskCache.containsObject(forKey: key)
        case .PINCache:
            print("PINCache \(pinCache.diskCache.containsObject(forKey: key) ? "hit" : "miss")")
            return pinCache.diskCache.containsObject(forKey: key)
        }
        
    }
    
    func path(forKey key: String) -> String? {
        switch selectedCache {
        case .YYCache:
            return assetCache.diskCache.path(forKey: key)
        case .PINCache:
            let url = pinCache.diskCache.videoFileURL(forKey:key)
            return url?.absoluteString
        }
    }
    
    func cache(object: Data?, forKey key: String) {
        switch selectedCache {
        case .YYCache:
            self.assetCache.diskCache.setData(object, forKey: key)
        case .PINCache:
            self.pinCache.diskCache.setVideoData(object!, forKey: key)
        }
    }
    
    func clearCache() {
        switch selectedCache {
        case .YYCache:
            AssetManager.sharedInstance.assetCache.diskCache.trim(toCount: 0)
            printCacheSize()
        case .PINCache:
            AssetManager.sharedInstance.pinCache.diskCache.trim(toSize: 1)
            printCacheSize()
        }
        
    }
    
    func printCacheSize() {
        switch selectedCache {
        case .YYCache:
            print("YYCache size = \(assetCache.diskCache.totalCost())")
        case .PINCache:
            print("PINCache size = \(pinCache.diskCache.byteCount)")
            
        }
    }
    
    //MARK: - Delegate Method
    
    func saveAVAsset(asset: PWAVURLAsset) {
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let filename = "temp.mp4"
        let documentsDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
        let outputURL = documentsDirectory.appendingPathComponent(filename)
        
        checkAndRemoveFile(atPath: outputURL.absoluteString)
       
        exporter?.outputURL = outputURL
        exporter?.outputFileType = AVFileTypeMPEG4
        
        exporter?.exportAsynchronously(completionHandler: {
            if let data = FileManager.default.contents(atPath: (exporter?.outputURL?.path)! ) {
                self.cache(object: data, forKey: asset.originalURLString!)
                AssetManager.sharedInstance.printCacheSize()
                self.checkAndRemoveFile(atPath: outputURL.absoluteString)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FinishedCachingVideo"), object: nil)
            }
        })
    }
    
    func checkAndRemoveFile(atPath path: String) {
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch let error{
                print(error)
            }
        }
    }
    
    
}

protocol CanSaveAVAsset{
    func saveAVAsset(asset: PWAVURLAsset)
}
