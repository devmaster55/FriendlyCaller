//
//  Session.swift
//  ReadFriendlyCaller
//
//  Created by Vedran Ozir on 11/02/16.
//  Modified by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit

@objc class Session: NSObject, NSCoding {
    
    static private var restoreKeyName = "v1.0/Session"
    
    static private var sessionCurrent = Session()
    
    internal var contacts: [Contact]
    
    override init() {
        
        contacts = [Contact]()
        
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        self.init()
        
        if let contacts = aDecoder.decodeObjectForKey("contacts") as? [Contact] {
            self.contacts = contacts
            
            reorder()
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeObject(contacts, forKey: "contacts")
    }
    
    class internal func current() -> Session {
        
        return sessionCurrent
    }
    
    class internal func setCurrent(session: Session) {
        
        sessionCurrent = session
    }
    
    class internal func restore() {
        
        if let
            archivedViewData = NSUserDefaults.standardUserDefaults().objectForKey(restoreKeyName) as? NSData,
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(archivedViewData) as? Session
        {
            
            for contact in session.contacts {
                
                if let imageId = contact.hashId where contact.imageExists {
                    
                    let keyName = restoreKeyName + "/image/\(imageId)"
                    
                    if let archivedViewData = NSUserDefaults.standardUserDefaults().objectForKey(keyName) as? NSData,
                        image = UIImage(data: archivedViewData) {
                            
                            NSLog("restored image size \(archivedViewData.length) \(keyName) \(image)")
                            
                            contact.image = image
                            contact.imageDirty = false
                    }
                }
            }
            
            sessionCurrent = session
        }
    }
    
    class internal func archive() {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            for contact in sessionCurrent.contacts {

                if contact.image != nil && contact.imageDirty {
                    
                    let keyName = restoreKeyName + "/image/\(contact.hashId)"
                    
                    if let image = contact.image {
                        
                        if let data = UIImagePNGRepresentation(image) {
                            
                            NSUserDefaults.standardUserDefaults().setObject(data, forKey: keyName)
                            
                            NSLog("stored image size \(data.length) \(keyName) \(image)")
                            
                            contact.imageDirty = false
                        }
                    }
                }
            }
            
            let data = NSKeyedArchiver.archivedDataWithRootObject(sessionCurrent)
            
            dispatch_async(dispatch_get_main_queue(), {
                
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: restoreKeyName)
                NSUserDefaults.standardUserDefaults().synchronize()
                
                NSLog("stored contacts list")
            })
        })
    }
    
    func addOrUpdate( contact: Contact) {

        // update
        var updated = false

        if self.contacts.count > 0 {
            for index in 0...contacts.count - 1 {
                
                let contactWalk = contacts[index]
                
                if contact == contactWalk {
                    
                    contactWalk.contactIdentifier = contact.contactIdentifier
                    contactWalk.cellularNumber = contact.cellularNumber
                    contactWalk.cellularNumberIdentifier = contact.cellularNumberIdentifier
                    contactWalk.image = contact.image
                    contactWalk.isSpecial = contact.isSpecial
                    updated = true
                    
                    break
                }
            }
        }
        
        // add
        if !updated {
            contacts.append(contact)
        }

        reorder()
    }
    
    func reorder() {
        // reorder for special contact
        var newContacts = [Contact]()
        
        if let specialContact = specialContact() {
            newContacts.append(specialContact)
        }
        
        for contactWalk in normalContacts() {
            newContacts.append(contactWalk)
        }
        
        contacts = newContacts
    }

    func moveContact(from:Int, to:Int) {
        let movedContact = contacts.removeAtIndex(from);
        contacts.insert(movedContact, atIndex: to)
    }
    
    func remove( contact: Contact) {
        
        var newContacts = [Contact]()
        
        for contactWalk in contacts {
            
            if contact != contactWalk {
                
                newContacts.append(contactWalk)
            }
        }
        
        contacts = newContacts
    }
    
    func normalContacts() -> [Contact] {
        
        var normalContacts : [Contact]
        
        normalContacts = [Contact] ()
        
        for contactWalk in contacts {
            
            if (contactWalk.isSpecial != true) {
                
                normalContacts.append(contactWalk)
            }
        }
        
        return normalContacts
    }
    
    func specialContact() -> Contact? {
        
        for contactWalk in contacts {
            
            if (contactWalk.isSpecial == true) {
                
                return contactWalk
            }
        }
        
        return nil
    }
    
    func isFirstLaunch() -> Bool {
        return !MasterUtil.sharedUtil().hasSetMasterPassword()
    }
}
