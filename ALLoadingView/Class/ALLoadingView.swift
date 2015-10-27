//
//  ALLoadingView.swift
//  ALLoadingView
//
//  Created by Артем Логинов on 13.09.15.
//  Copyright (c) 2015 ALoginov. All rights reserved.
//

import UIKit

typealias ALLVCompletionBlock = () -> Void

enum ALLVType {
    case Default
    case BigActivityIndicator
    case Message
    case Progress
}

enum ALLVWindowMode {
    case Fullsreen
    case Windowed
}

private enum ALLVProgress {
    case Hidden
    case Initializing
    case ViewReady
    case Loaded
    case Hiding
}

class ALLoadingView: NSObject {
    //MARK: - Public variables
    var animationDuration: CGFloat = 0.5
    var cornerRadius: CGFloat = 0.0
    lazy var backgroundColor: UIColor = UIColor(white: 0.0, alpha: 0.5)
    lazy var textColor: UIColor = UIColor(white: 1.0, alpha: 1.0)
    lazy var messageFont: UIFont = UIFont.systemFontOfSize(25.0)
    lazy var messageText: String = "Loading"
    
    //MARK: - Private variables
    private var loadingViewProgress: ALLVProgress
    private var loadingViewType: ALLVType
    private var loadingView: UIView = UIView()
    private var operationQueue = NSOperationQueue()
    private let progressBar = UIProgressView(frame: CGRect(origin: CGPointZero, size: CGSizeZero))
    private let messageLabel = UILabel(frame: CGRect(origin: CGPointZero, size: CGSizeZero))
    //MARK: Custom setters/getters
    private var loadingViewWindowMode: ALLVWindowMode {
        didSet {
            if loadingViewWindowMode == ALLVWindowMode.Fullsreen {
                cornerRadius = 0.0
            } else {
                cornerRadius = 10.0
            }
        }
    }
    private var frameForView: CGRect {
        if loadingViewWindowMode == .Fullsreen {
            return UIScreen.mainScreen().bounds
        } else {
            let bounds = UIScreen.mainScreen().bounds;
            let size = min(CGRectGetWidth(bounds), CGRectGetHeight(bounds))
            return CGRectMake(0, 0, size * 0.4, size * 0.4)
        }
    }
    
    //MARK: - Initialization
    class var manager: ALLoadingView {
        struct Singleton {
            static let instance = ALLoadingView()
        }
        return Singleton.instance
    }
    
    override init() {
        loadingViewWindowMode = .Fullsreen
        loadingViewProgress = .Hidden
        loadingViewType = .Default
    }
    
    //MARK: - Public methods
    func showLoadingViewOfType(type: ALLVType) {
        showLoadingViewOfType(type) {
            (finished) -> Void in
        }
    }
    
    func showLoadingViewOfType(type: ALLVType, completionBlock: ALLVCompletionBlock?) {
        showLoadingViewOfType(type, windowMode: .Fullsreen, completionBlock: completionBlock)
    }
    
    func showLoadingViewOfType(type: ALLVType, windowMode: ALLVWindowMode, completionBlock: ALLVCompletionBlock? = nil) {
        assert(loadingViewProgress == .Hidden || loadingViewProgress == .Hiding, "ALLoadingView Presentation Error. Trying to push loading view while one already presented")
        
        loadingViewProgress = .Initializing
        loadingViewWindowMode = windowMode
        loadingViewType = type
        
        let operationInit = NSBlockOperation { () -> Void in
            self.loadingView = UIView(frame: UIScreen.mainScreen().bounds)
            switch self.loadingViewType {
            case .Default:
                self.initializeDefaultLoadingView()
                break
            case .BigActivityIndicator:
                self.initializeBigIndicatorLoadingView()
                break
            case .Message:
                self.initializeMessageLoadingView()
                break
            case .Progress:
                self.initializeProgressLoadingView()
                break
            }
        }
        
        let operationShow = NSBlockOperation { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().windows[0].addSubview(self.loadingView)
                self.loadingView.alpha = 0.0
                
                switch self.loadingViewType {
                case .Message:
                    for view in self.loadingView.subviews {
                        if view.respondsToSelector("setText:") {
                            view .performSelectorOnMainThread("setText:", withObject: self.messageText, waitUntilDone: false)
                        }
                    }
                    break
                case .Progress:
                    for view in self.loadingView.subviews {
                        if view.respondsToSelector("setProgress:") {
                            (view as! UIProgressView).progress = 0.0
                        }
                        if view.respondsToSelector("setText:") {
                            (view as! UILabel).text = self.messageText
                        }
                    }
                    break
                default:
                    break
                }
                
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.loadingView.alpha = 1
                    }) { finished -> Void in
                        if finished {
                            self.loadingViewProgress = .Loaded
                            completionBlock?()
                        }
                }
            }
        }
        
        operationShow.addDependency(operationInit)
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperations([operationInit, operationShow], waitUntilFinished: false)
    }
    
    func hideLoadingView(completionBlock: ALLVCompletionBlock? = nil) {
        loadingViewProgress = .Hiding
        
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.loadingView.alpha = 0.0
                }) { (finished) -> Void in
                    self.loadingViewProgress = .Hidden
                    self.loadingView.removeFromSuperview()
                    completionBlock?()
                    self.freeViewData()
            }
        }
    }
    
    func updateProgressLoadingViewWithMessage(message: String, forProgress progress: Float) {
        assert(loadingViewType == .Progress, "ALLoadingView Update Error. Set Progress type to access progress bar.")
        if self.loadingViewProgress != .Loaded { return }
        
        
        dispatch_async(dispatch_get_main_queue()) {
            for view in self.loadingView.subviews {
                if view.respondsToSelector("setText:") {
                    view .performSelectorOnMainThread("setText:", withObject: message, waitUntilDone: false)
                }
                if view.respondsToSelector("setProgress:") {
                    (view as! UIProgressView).setProgress(progress, animated: true)
                }
            }
        }
    }
    
    //MARK: - Private methods
    private func initializeDefaultLoadingView() {
        self.loadingView = UIView(frame: frameForView)
        self.loadingView.center = CGPointMake(CGRectGetMidX(UIScreen.mainScreen().bounds), CGRectGetMidY(UIScreen.mainScreen().bounds))
        self.loadingView.backgroundColor = self.backgroundColor
        self.loadingView.layer.cornerRadius = cornerRadius
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
//        activityIndicator.center = self.loadingView.center
        activityIndicator.center = CGPointMake(CGRectGetMidX(self.loadingView.bounds), CGRectGetMidY(self.loadingView.bounds))
        activityIndicator.startAnimating()
        self.loadingView.addSubview(activityIndicator)
        
        self.loadingViewProgress = .ViewReady
    }
    
    private func initializeBigIndicatorLoadingView() {
        self.loadingView = UIView(frame: UIScreen.mainScreen().bounds)
        self.loadingView.backgroundColor = self.backgroundColor
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicator.center = self.loadingView.center
        activityIndicator.startAnimating()
        self.loadingView.addSubview(activityIndicator)
        
        self.loadingViewProgress = .ViewReady
    }
    
    private func initializeMessageLoadingView() {
        self.loadingView = UIView(frame: UIScreen.mainScreen().bounds)
        self.loadingView.backgroundColor = self.backgroundColor
        let bounds = loadingView.bounds
        // Activity indicator
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicator.startAnimating()
        self.loadingView.addSubview(activityIndicator)
        // Label
        let label = UILabel(frame: CGRectMake(0, CGRectGetHeight(bounds)/2 - 75.0, CGRectGetWidth(bounds), 50.0))
        label.textAlignment = .Center
        label.textColor = textColor
        label.font = messageFont
        // Place on screen
        self.loadingView.addSubview(label)
        activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(label.frame) + 50.0)
        self.loadingViewProgress = .ViewReady
    }
    
    private func initializeProgressLoadingView() {
        self.loadingView = UIView(frame: UIScreen.mainScreen().bounds)
        self.loadingView.backgroundColor = self.backgroundColor
        let bounds = loadingView.bounds
        
        // Label
        messageLabel.frame = CGRectMake(0, CGRectGetHeight(bounds)/2 - 75.0, CGRectGetWidth(bounds), 50.0)
        messageLabel.textAlignment = .Center
        messageLabel.textColor = textColor
        messageLabel.font = messageFont
        
        // Progress view
        progressBar.progressViewStyle = .Default
        progressBar.frame.size = CGSizeMake(CGRectGetWidth(bounds) - 40, 10)
        progressBar.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(messageLabel.frame) + 50.0)
        
        // Place on screen
        self.loadingView.addSubview(messageLabel)
        self.loadingView.addSubview(progressBar)

        self.loadingViewProgress = .ViewReady
    }
    
    private func freeViewData() {
        // View is hidden, now free memory
        for subview in self.loadingView.subviews {
            subview.removeFromSuperview()
        }
        self.loadingView = UIView(frame: CGRectZero);
    }
}