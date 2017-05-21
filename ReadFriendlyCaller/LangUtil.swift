//
//  LangUtil.swift
//  ReadFriendlyCaller
//
//  Created by Ou Yang Shao Bo on 2/29/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import Foundation
import UIKit

class LangUtil : NSObject {
    
    static private var STORE_KEY_LANG = "lang"
    
    static private var _sharedUtil = LangUtil()
    
    override init() {
        super.init()
        
        if NSUserDefaults.standardUserDefaults().objectForKey(LangUtil.STORE_KEY_LANG) == nil {
            self.setLocale("en")
        }
    }
    
    class internal func sharedUtil() -> LangUtil {
        return _sharedUtil
    }
    
    func chooseLanguage(targetVC: UIViewController, handler: (Void->())!) {
        
        let title = "Choose Your Language:".localized(getLocale())
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        // English
        alert.addAction(UIAlertAction(title: "English", style: UIAlertActionStyle.Default, handler: {
            action in
            
            self.setLocale("en")
            if handler != nil {
                handler()
            }
        }))
        
        // Arabic
        alert.addAction(UIAlertAction(title: "العربية", style: UIAlertActionStyle.Default, handler: {
            action in
            
            self.setLocale("ar")
            if handler != nil {
                handler()
            }
        }))
        
        // Spanish
        alert.addAction(UIAlertAction(title: "Español", style: UIAlertActionStyle.Default, handler: {
            action in
            
            self.setLocale("es")
            if handler != nil {
                handler()
            }
        }))
        
        // French
        alert.addAction(UIAlertAction(title: "français", style: UIAlertActionStyle.Default, handler: {
            action in
            
            self.setLocale("fr")
            if handler != nil {
                handler()
            }
        }))
        
        targetVC.presentViewController(alert, animated: true, completion: nil)
    }
    
    func setLocale(locale: String) {
        NSUserDefaults.standardUserDefaults().setObject(locale, forKey: LangUtil.STORE_KEY_LANG)
    }
    
    func getLocale() -> String {
        return NSUserDefaults.standardUserDefaults().objectForKey(LangUtil.STORE_KEY_LANG) as! String
    }
    
}