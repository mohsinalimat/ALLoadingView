//
//  ViewController.swift
//  ALLoadingView
//
//  Created by Артем Логинов on 13.09.15.
//  Copyright (c) 2015 ALoginov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var step: Int = 0
    private var updateTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func action_testCaseOne(sender: AnyObject) {
        _ = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "stopTimer", userInfo: nil, repeats: false)
        
//        ALLoadingView.manager.showLoadingViewOfType(.Default)
        ALLoadingView.manager.showLoadingViewOfType(.Default, windowMode: ALLVWindowMode.Fullsreen, completionBlock: nil)
    }
    
    @IBAction func action_testCaseTwo(sender: AnyObject) {
        _ = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "stopTimer", userInfo: nil, repeats: false)
        
//        ALLoadingView.manager.showLoadingViewOfType(.BigActivityIndicator)
        ALLoadingView.manager.showLoadingViewOfType(.Default, windowMode: ALLVWindowMode.Windowed, completionBlock: nil)
    }
    
    @IBAction func action_testCaseThree(sender: AnyObject) {
        _ = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "stopTimer", userInfo: nil, repeats: false)
        
        ALLoadingView.manager.showLoadingViewOfType(.Message)
    }
    
    @IBAction func action_testCaseFour(sender: AnyObject) {
        NSTimer.scheduledTimerWithTimeInterval(6.0, target: self, selector: "stopTimer", userInfo: nil, repeats: false)
        
        step = 0
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
            updateTimer.invalidate()
        }
    }
    
    func stopTimer() {
        print("stopping", terminator: "")
        ALLoadingView.manager.hideLoadingView { (finished) -> Void in
            print("stopped", terminator: "")
        }
    }
}

