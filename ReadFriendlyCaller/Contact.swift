//
//  Contact.swift
//  ReadFriendlyCaller
//
//  Created by Vedran Ozir on 11/02/16.
//  Modified by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit
import Contacts

class Contact: NSObject, NSCoding {

    internal var image: UIImage? { didSet { imageExists = true; imageDirty = true } }
    internal var imageExists = false
    internal var imageDirty = false
    
    internal var hashId: Int!
    
    internal var contactIdentifier: String!
    
    internal var isSpecial: Bool!
    
    internal var cellularNumber: String?
    internal var cellularNumberIdentifier: String!
    
    override init() {
        
        super.init()

        hashId = hashValue
        contactIdentifier = ""
        cellularNumberIdentifier = ""
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init()

        contactIdentifier = aDecoder.decodeObjectForKey("contactIdentifier") as? String
        hashId = aDecoder.decodeObjectForKey("hashId") as? Int
        
        if let imageExists = aDecoder.decodeObjectForKey("imageExists") as? Bool {
            self.imageExists = imageExists
        }
        
        cellularNumber = aDecoder.decodeObjectForKey("cellularNumber") as? String
        cellularNumberIdentifier = aDecoder.decodeObjectForKey("cellularNumberIdentifier") as? String
        
        isSpecial = aDecoder.decodeObjectForKey("isSpecial") as? Bool
        
        
        
//        NSLog("decoding contact \(hashId)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
//        NSLog("encoding contact \(hashId)")
        aCoder.encodeObject(contactIdentifier, forKey: "contactIdentifier")
        aCoder.encodeObject(hashId, forKey: "hashId")
        
        aCoder.encodeObject(imageExists, forKey: "imageExists")
        
        aCoder.encodeObject(cellularNumber, forKey: "cellularNumber")
        aCoder.encodeObject(cellularNumberIdentifier, forKey: "cellularNumberIdentifier")
        
        aCoder.encodeObject(isSpecial, forKey: "isSpecial")
        
    }
    
    func syncToApp() {
        if self.contactIdentifier.characters.count > 0 {
            if let contact = AddressBookUtil.sharedUtil().getContact(self.contactIdentifier) {
                
                var photoChanged = false
                
                let imageNew = UIImage(data: contact.imageData!)
                if let imageOld = self.image {
                    let data1 = UIImagePNGRepresentation(imageOld)!
                    let data2 = UIImagePNGRepresentation(imageNew!)!
                    
                    if !data1.isEqualToData(data2) {
                        photoChanged = true
                        self.image = imageNew
                    }
                }
                
                var phoneNumberGot = false
                for phoneNumber in contact.phoneNumbers {
                    if (phoneNumber.identifier == self.cellularNumberIdentifier) {
                        self.cellularNumber = (phoneNumber.value as! CNPhoneNumber).stringValue
                        phoneNumberGot = true
                        break
                    }
                }
                
                if !phoneNumberGot {
                    if contact.phoneNumbers.count > 0 {
                        self.cellularNumber = (contact.phoneNumbers[0].value as! CNPhoneNumber).stringValue
                        self.cellularNumberIdentifier = contact.phoneNumbers[0].identifier
                    } else {
                        self.cellularNumber = ""
                        self.cellularNumberIdentifier = ""
                    }
                    
                    CloudUtil.sharedUtil().saveContacts(nil)
                }
                
                if photoChanged {
                    let vc = (UIApplication.sharedApplication().delegate as? AppDelegate)!.window?.rootViewController
                    
                    DIY.showLoading(vc!, message: "Saving changes...".localized(LangUtil.sharedUtil().getLocale())!, todo: { () in
                        
                        CloudUtil.sharedUtil().uploadImage(self, completion: { (storagePath) in
                            DIY.dismissLoading(vc!, completion: {
                                if storagePath == nil {
                                    DIY.alertConnectionError(vc!)
                                } else {
                                    vc!.dismissViewControllerAnimated(true, completion: nil)
                                }
                            })
                        })
                    })
                }
            }
        }
    }
    
    func syncToAddressBook() {
        if self.contactIdentifier.characters.count == 0 {
            AddressBookUtil.sharedUtil().addContact(self)
        } else {
            AddressBookUtil.sharedUtil().updateContact(self)
        }
    }
}