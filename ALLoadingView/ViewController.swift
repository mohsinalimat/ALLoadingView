//
//  ViewController.swift
//  ALLoadingView
//
//  Created by Артем Логинов on 13.09.15.
//  Copyright (c) 2015 ALoginov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var step = 0
    private var updateTimer = NSTimer()

    @IBAction func action_testCaseOne(sender: AnyObject) {
        ALLoadingView.manager.resetToDefaults()
        ALLoadingView.manager.showLoadingViewOfType(.Default, windowMode: .Windowed, completionBlock: nil)
        ALLoadingView.manager.hideLoadingViewWithDelay(2.0)
    }
    
    @IBAction func action_testCaseTwo(sender: AnyObject) {
        ALLoadingView.manager.resetToDefaults()
        ALLoadingView.manager.bluredBackground = true
        ALLoadingView.manager.showLoadingViewOfType(.MessageWithIndicator, windowMode: ALLVWindowMode.Fullsreen, completionBlock: nil)
        ALLoadingView.manager.hideLoadingViewWithDelay(2.0)
    }
    
    @IBAction func action_testCaseThree(sender: AnyObject) {
        ALLoadingView.manager.resetToDefaults()
        ALLoadingView.manager.bluredBackground = true
        ALLoadingView.manager.showLoadingViewOfType(.MessageWithIndicatorAndCancelButton, windowMode: ALLVWindowMode.Fullsreen, completionBlock: nil)
        ALLoadingView.manager.cancelCallback = {
            ALLoadingView.manager.hideLoadingView()
        }
    }
    
    @IBAction func action_testCaseFour(sender: AnyObject) {
        ALLoadingView.manager.resetToDefaults()
        ALLoadingView.manager.showLoadingViewOfType(.Progress) {
            (finished) -> Void in
            ALLoadingView.manager.updateProgressLoadingViewWithMessage("Initializing", forProgress: 0.05)
            self.step = 1
            self.updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        }
    }
    
    func updateProgress() {
        let steps = ["Initializing", "Downloading data", "Extracting files", "Parsing data", "Updating database", "Saving"]
        ALLoadingView.manager.updateProgressLoadingViewWithMessage(steps[step], forProgress: 0.2 * Float(step))
        step++
        if step == steps.count {
            ALLoadingView.manager.hideLoadingView()
            updateTimer.invalidate()
        }
    }
}

