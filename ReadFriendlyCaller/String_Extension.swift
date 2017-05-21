//
//  String_Extension.swift
//  ReadFriendlyCaller
//
//  Created by Ou Yang Shao Bo on 2/29/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import Foundation

extension String {
    func localized(locale:String) -> String? {
        
        if locale == "en" {
            return self
        }
        
        let path = NSBundle.mainBundle().pathForResource(locale, ofType: "strings")
        let dict = NSDictionary(contentsOfFile: path!)
        
        if let localized_str = dict!.objectForKey(self) {
            return localized_str as? String
        } else {
            print("\(locale) of \"\(self)\" not found")
            return self
        }
    }
}