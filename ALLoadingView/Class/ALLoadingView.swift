//
//  ALLoadingView.swift
//  ALLoadingView
//
//  Created by Артем Логинов on 13.09.15.
//  Copyright (c) 2015 ALoginov. All rights reserved.
//

import UIKit

typealias ALLVCompletionBlock = () -> Void
typealias ALLVCancelBlock = () -> Void

enum ALLVType {
    case Default
    case Message
    case MessageWithIndicator
    case MessageWithIndicatorAndCancelButton
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

// building blocks
private enum ALLVViewType {
    case BlankSpace
    case MessageLabel
    case ProgressBar
    case CancelButton
    case ActivityIndicator
}

class ALLoadingView: NSObject {
    //MARK: - Public variables
    var animationDuration: NSTimeInterval = 0.5
    var cornerRadius: CGFloat = 0.0
    var cancelCallback: ALLVCancelBlock?
    var bluredBackground: Bool = false
    lazy var backgroundColor: UIColor = UIColor(white: 0.0, alpha: 0.5)
    lazy var textColor: UIColor = UIColor(white: 1.0, alpha: 1.0)
    lazy var messageFont: UIFont = UIFont.systemFontOfSize(25.0)
    lazy var messageText: String = "Loading"
    //MARK: Adjusment
    var windowRatio: CGFloat = 0.4 {
        didSet {
            windowRatio = min(max(0.2, windowRatio), 1.0)
        }
    }
    
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
            if loadingViewWindowMode == .Fullsreen {
                cornerRadius = 0.0
            } else  {
                bluredBackground = false
                if cornerRadius == 0.0 {
                    cornerRadius = 10.0
                }
            }
        }
    }
    private var frameForView: CGRect {
        if loadingViewWindowMode == .Fullsreen {
            return UIScreen.mainScreen().bounds
        } else {
            let bounds = UIScreen.mainScreen().bounds;
            let size = min(CGRectGetWidth(bounds), CGRectGetHeight(bounds))
            return CGRectMake(0, 0, size * windowRatio, size * windowRatio)
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
    //MARK: Show loading view
    func showLoadingViewOfType(type: ALLVType, completionBlock: ALLVCompletionBlock?) {
        showLoadingViewOfType(type, windowMode: .Fullsreen, completionBlock: completionBlock)
    }
    
    func showLoadingViewOfType(type: ALLVType, windowMode: ALLVWindowMode, completionBlock: ALLVCompletionBlock? = nil) {
        assert(loadingViewProgress == .Hidden || loadingViewProgress == .Hiding, "ALLoadingView Presentation Error. Trying to push loading view while there is one already presented")
        
        loadingViewProgress = .Initializing
        loadingViewWindowMode = windowMode
        loadingViewType = type
        
        let operationInit = NSBlockOperation { () -> Void in
            self.initializeLoadingView()
        }
        
        let operationShow = NSBlockOperation { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().windows[0].addSubview(self.loadingView)
                self.loadingView.alpha = 0.0
                
                switch self.loadingViewType {
                case .Message, .MessageWithIndicator:
                    for view in self.loadingView.subviews {
                        if view.respondsToSelector("setText:") {
                            view.performSelectorOnMainThread("setText:", withObject: self.messageText, waitUntilDone: false)
                        }
                    }
                    break
                case .MessageWithIndicatorAndCancelButton:
                    for view in self.loadingView.subviews {
                        if view.respondsToSelector("setTitle:") {
                            (view as! UIButton).setTitle("Cancel1", forState: .Normal)
                        }
                        if view.respondsToSelector("setText:") {
                            view.performSelectorOnMainThread("setText:", withObject: self.messageText, waitUntilDone: false)
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
    
    //MARK: Hide loading view
    func hideLoadingView(completionBlock: ALLVCompletionBlock? = nil) {
        hideLoadingViewWithDelay(0.0) { () -> Void in
            completionBlock?()
        }
    }
    
    func hideLoadingViewWithDelay(delay: NSTimeInterval, completionBlock: ALLVCompletionBlock? = nil) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.loadingViewProgress = .Hiding
            UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                self.loadingView.alpha = 0.0
                }) { finished -> Void in
                    if finished {
                        self.loadingViewProgress = .Hidden
                        self.loadingView.removeFromSuperview()
                        completionBlock?()
                        self.freeViewData()
                    }
            }
        }
    }
    
    //MARK: Updating subviews data
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
    
    func updateMessageLabelWithText(message: String) {
        assert(loadingViewType == .Message ||
               loadingViewType == .MessageWithIndicator ||
               loadingViewType == .MessageWithIndicatorAndCancelButton, "ALLoadingView Update Error. Set .Message, .MessageWithIndicator and .MessageWithIndicatorAndCancelButton type to access message label.")
        if self.loadingViewProgress != .Loaded { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            for view in self.loadingView.subviews {
                if view.respondsToSelector("setText:") {
                    view .performSelectorOnMainThread("setText:", withObject: message, waitUntilDone: false)
                }
            }
        }
    }
    
    //MARK: - Private methods
    //MARK: Initialize view
    private func initializeLoadingView() {
        // create loading view
        NSLog("Create")
        loadingView = UIView(frame: frameForView)
        loadingView.center = CGPointMake(CGRectGetMidX(UIScreen.mainScreen().bounds), CGRectGetMidY(UIScreen.mainScreen().bounds))
        loadingView.layer.cornerRadius = cornerRadius
        if self.loadingViewWindowMode == .Fullsreen && self.bluredBackground {
            
            loadingView.backgroundColor = .clearColor()
            NSLog("Background")
            let greenView = UIView(frame: CGRect(x: 50, y: 50, width: 50, height: 50))
            greenView.backgroundColor = .greenColor()
            loadingView.addSubview(greenView)
            
//            let imageView = UIImageView(frame: loadingView.bounds)
//            
//            imageView.contentMode = .ScaleToFill
//            loadingView.addSubview(imageView)
//            loadingView.sendSubviewToBack(imageView)
//            
//            let layer = UIApplication.sharedApplication().keyWindow!.layer
//            let scale = UIScreen.mainScreen().scale
//            UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
//            
//            layer.renderInContext(UIGraphicsGetCurrentContext()!)
//            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            NSLog("Image")
//            let blurred = self.applyBlurEffect(screenshot)
//            
//            dispatch_async(dispatch_get_main_queue()) {
//                imageView.image = blurred
////                imageView.image = self.applyBlurEffect(screenshot)
//            }
        } else {
            loadingView.backgroundColor = backgroundColor
        }
        
        // get list of views
        let viewTypes = specifySubviewTypes()
        
        // calculate frame for each view
        let viewsCount: Int = viewTypes.count
        let elementHeight: CGFloat = CGRectGetHeight(frameForView) / CGFloat(viewsCount)
        
        // iterate
        for (index, type) in viewTypes.enumerate() {
            let frame: CGRect = CGRectMake(0, elementHeight * CGFloat(index), CGRectGetWidth(frameForView), elementHeight)
            let view = initializeViewWithType(type, andFrame: frame)
            
            self.loadingView.addSubview(view)
            self.loadingView.bringSubviewToFront(view)
//            if bluredBackground {
//                if let blurEffectView = self.loadingView.subviews.first as? UIVisualEffectView {
//                    blurEffectView.contentView.addSubview(view)
//                }
//            } else {
//                self.loadingView.addSubview(view)
//            }
        }
        
        // done
        self.loadingViewProgress = .ViewReady
    }
    
    private func specifySubviewTypes() -> [ALLVViewType] {
        switch self.loadingViewType {
        case .Default:
            return [.ActivityIndicator]
        case .Message:
            return [.MessageLabel]
        case .MessageWithIndicator:
            return [.MessageLabel, .ActivityIndicator]
        case .MessageWithIndicatorAndCancelButton:
            if self.loadingViewWindowMode == ALLVWindowMode.Windowed {
                return [.MessageLabel, .ActivityIndicator, .CancelButton]
            } else {
                return [.BlankSpace, .BlankSpace, .MessageLabel, .ActivityIndicator, .BlankSpace, .CancelButton]
            }
        default:
            return [.ActivityIndicator]
        }
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
    
    //MARK: Initializing subviews
    private func initializeViewWithType(type: ALLVViewType, andFrame frame: CGRect) -> UIView {
        switch type {
        case .MessageLabel:
            return view_messageLabel(frame)
        case .ActivityIndicator:
            return view_activityIndicator(frame)
        case .CancelButton:
            return view_cancelButton(frame)
        case .BlankSpace:
            return UIView(frame: frame)
        default:
            return view_messageLabel(frame)
        }
    }
    
    private func view_activityIndicator(frame: CGRect) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityIndicator.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    private func view_messageLabel(frame: CGRect) -> UILabel {
        let label = UILabel(frame: frame)
        label.textAlignment = .Center
        label.textColor = textColor
        label.font = messageFont
        return label
    }
    
    private func view_cancelButton(frame: CGRect) -> UIButton {
        let button = UIButton(type: .Custom)
        button.frame = frame
        button.setTitle("Cancel", forState: .Normal)
        button.setTitleColor(.whiteColor(), forState: .Normal)
        button.backgroundColor = .clearColor()
        button.addTarget(self, action: "cancelButtonTapped:", forControlEvents: .TouchUpInside)
        return button
    }
    
    //MARK: Subviews actions
    func cancelButtonTapped(sender: AnyObject?) {
        if let _ = sender as? UIButton {
            cancelCallback?()
        }
    }
    
    //MARK: Apply blur to image
    func applyBlurEffect(image: UIImage) -> UIImage {
        let imageToBlur = CIImage(image: image)
        let blurfilter = CIFilter(name: "CIGaussianBlur")
        blurfilter!.setValue(imageToBlur, forKey: "inputImage")
        let resultImage = blurfilter!.valueForKey("outputImage") as! CIImage
        return UIImage(CIImage: resultImage)
    }
}