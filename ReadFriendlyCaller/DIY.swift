//
//  DIY.swift
//  Nearby Coupons
//
//  Created by Kun.Zhang on 6/3/16.
//  Copyright © 2016 Desolf Team. All rights reserved.
//

import UIKit
import AdSupport

class DIY {
    
    static var loadingCount : Int = 0
    
    static func getUserID() -> String {
        return ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
    }
    
    static func alertConnectionError(vc: UIViewController) {
        let alert = UIAlertController(title: nil, message: "Please check your connection and try again!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        vc.presentViewController(alert, animated: true, completion: nil)
    }
    
    static func showLoading(viewController: UIViewController, message: String, todo: (Void -> ())!) {
        
        loadingCount += 1
        
        if loadingCount == 1 {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
            
            alert.view.tintColor = UIColor.blackColor()
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50)) as UIActivityIndicatorView
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            loadingIndicator.startAnimating();
            alert.view.addSubview(loadingIndicator)
            
            viewController.presentViewController(alert, animated: true) {
                if todo != nil {
                    todo()
                }
            }
        }
    }
    
    static func dismissLoading(viewController: UIViewController, completion: (() -> Void)?) {
        loadingCount -= 1
        if loadingCount == 0 {
            viewController.dismissViewControllerAnimated(true, completion: completion)
        }
    }
    
    static func ask(viewController: UIViewController, title: String?, message: String?, btn_yes: String?, yes_handler: (Void->())!, btn_no: String?, no_handler: (Void->())!) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: btn_yes, style: .Default, handler: {
            action in
            if yes_handler != nil {
                yes_handler()
            }
        }))
        
        alert.addAction(UIAlertAction(title: btn_no, style: .Default, handler: {
            action in
            if no_handler != nil {
                no_handler()
            }
        }))
        
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
}