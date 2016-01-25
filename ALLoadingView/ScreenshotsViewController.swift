//
//  ScreenshotsViewController.swift
//  ALLoadingView
//
//  Created by Artem Loginov on 25.01.16.
//  Copyright © 2016 ALoginov. All rights reserved.
//

import UIKit

class ScreenshotsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        ALLoadingView.manager.resetToDefaults()
        ALLoadingView.manager.bluredBackground = true
        ALLoadingView.manager.messageText = "Fetching data"
        ALLoadingView.manager.messageFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        ALLoadingView.manager.showLoadingViewOfType(.MessageWithIndicatorAndCancelButton, windowMode: .Fullscreen, completionBlock: nil)
//        ALLoadingView.manager.hideLoadingViewWithDelay(2.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
