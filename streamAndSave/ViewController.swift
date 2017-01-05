//
//  ViewController.swift
//  streamAndSave
//
//  Created by Rongbo Yang on 12/27/16.
//  Copyright © 2016 Rongbo Yang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //MARK: - Accessors
    
    fileprivate var context = 0

    lazy var spinnerView: SpinnerView = {
        var spinnerView = SpinnerView()
        spinnerView.frame = UIScreen.main.bounds
        spinnerView.spinner.center = self.view.center
        return spinnerView
    }()
    
    lazy var player: AVPlayer = {
        var player: AVPlayer = AVPlayer(playerItem: self.playerItem)
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        return player
    }()
    
    lazy var playerItem: AVPlayerItem = {
        var playerItem: AVPlayerItem = AVPlayerItem(asset: self.asset)
        return playerItem
    }()
    
    var asset: PWAVURLAsset {
        get {
            var url: URL?
            if  AssetManager.sharedInstance.containsObject(forKey: self.urlString!) {
                let localURL = AssetManager.sharedInstance.path(forKey: self.urlString!)
                url = URL(string: "file://\(localURL!)")
            } else {
                url = URL(string: self.urlString!)
            }
            
            let asset: PWAVURLAsset = PWAVURLAsset(url: url!)
            asset.originalURLString = self.urlString!
            asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
            return asset
        }
    }
    
    lazy var playerLayer: AVPlayerLayer = {
        var playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = UIScreen.main.bounds
        playerLayer.backgroundColor = UIColor.clear.cgColor
        return playerLayer
    }()
    
    lazy var urlString: String? = {
  
        return "http://d2bgg7rjywcwsy.cloudfront.net/videos/119179/592417/encoded/1280_720_1280x720.mp4"
//        return "http://sendvid.com/l9yydre4.mp4"
//        return "http://sendvid.com/jbxxzeev.mp4"
//        return "http://techslides.com/demos/sample-videos/small.mp4"
//        return "http://sendvid.com/akztojrg.mp4"
    }()
    
    var delegate: CanSaveAVAsset {
        get {
            return AssetManager.sharedInstance
        }
    }
    
    //MARK: - UI Outlets
    
    @IBOutlet weak var dismissButton: UIButton!
    
    //MARK: - ButtonActions
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
        playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &context)
        
        player.replaceCurrentItem(with: playerItem)
        
        view.layer.addSublayer(playerLayer)
        view.addSubview(spinnerView)
        
        player.play()
        dismissButton.isHidden = false
    }
    
    @IBAction func clearCache(_ sender: UIButton) {
        AssetManager.sharedInstance.clearCache()
        presentAlert(withTitle: "Cache has been cleared", andMessage: "Cache has been cleared")
    }

    @IBAction func cacheSelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            AssetManager.sharedInstance.selectedCache = selectedCache.YYCache
        case 1:
            AssetManager.sharedInstance.selectedCache = selectedCache.PINCache
        default:
            AssetManager.sharedInstance.selectedCache = selectedCache.YYCache
        }
    }
    
    @IBAction func dismissVideoPlayer(_ sender: UIButton) {
        playerLayer.removeFromSuperlayer()
        playerItem.removeObserver(self, forKeyPath: "status", context: &context)
        player.replaceCurrentItem(with: nil)
        dismissButton.isHidden = true
    }
    
    //MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder:aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemPlaybackStalled(_:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishedCachingVideo), name: NSNotification.Name(rawValue: "FinishedCachingVideo"), object: nil)
    }
    
    //MARK: - ViewLifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        dismissButton.isHidden = true
    }
    

    //MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.context {
            if let object = object {
                if (object as AnyObject).isKind(of: AVPlayerItem.self) {
                    let item = object as! AVPlayerItem
                    switch item.status {
                    case .failed:
                        ()
                    case .readyToPlay:
                        spinnerView.removeFromSuperview()
                        playerItemDidReachEnd2()
                    case .unknown:
                        ()
                    }
                }
            }
        }
    }
    
    //MARK: - Notifications

    func playerItemDidReachEnd(_ notification: Notification) {
        
        if notification.object as? AVPlayerItem  == player.currentItem {
            player.pause()
            player.seek(to: kCMTimeZero)
            player.play()
        }
    }
    
    func playerItemDidReachEnd2() {
        if !AssetManager.sharedInstance.containsObject(forKey: asset.originalURLString!) {
            delegate.saveAVAsset(asset: asset)
        }
    }
    
    func playerItemPlaybackStalled(_ notification: Notification) {
        player.pause()
    }
    
    func didFinishedCachingVideo() {
        presentAlert(withTitle: "Cached!", andMessage: "The video has been cached successfully!")
    }
    
    func presentAlert(withTitle title: String, andMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
    
    //MARK: - Deinit

    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
        playerItem.removeObserver(self, forKeyPath: "status", context: &context)
    }
}

extension ViewController: AVAssetResourceLoaderDelegate {
    
}

class PWAVURLAsset: AVURLAsset {
    var originalURLString: String?
}
