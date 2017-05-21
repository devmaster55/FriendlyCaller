//
//  AddressBook.swift
//  ReadFriendlyCaller
//
//  Created by Kun.Zhang on 7/5/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import Foundation
import Contacts
import UIKit

class AddressBookUtil : NSObject {
    
    static private var _sharedUtil = AddressBookUtil()
    
    override init() {
        super.init()

    }
    
    class internal func sharedUtil() -> AddressBookUtil {
            
        return _sharedUtil
    }
    
    
    func printAllContacts() {
        let store = CNContactStore()
        
        do {
            let contacts = try store.unifiedContactsMatchingPredicate(CNContact.predicateForContactsInContainerWithIdentifier(store.defaultContainerIdentifier()), keysToFetch: [
                CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
                CNContactPhoneNumbersKey,
                CNContactThumbnailImageDataKey]
                )
            
            for contact in contacts {
                print(contact.identifier, contact.givenName)
            }
        } catch {
            print("nothing")
        }
    }

    func getContact(identifier: String) -> CNMutableContact? {

        let store = CNContactStore()
        
        do {
            let contact = try store.unifiedContactWithIdentifier(identifier, keysToFetch: [
                    CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
                    CNContactPhoneNumbersKey,
                    CNContactImageDataKey,
                    CNContactThumbnailImageDataKey]
            )
            
            return contact.mutableCopy() as? CNMutableContact
        } catch {
            print("get contact failed")
        }
        
        return nil
    }
    
    func addContact(contact: Contact) {
        
        let newContact = CNMutableContact()
        
        newContact.imageData = UIImagePNGRepresentation(contact.image!)
        let phoneNumberValue = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: contact.cellularNumber!))
        newContact.phoneNumbers = [phoneNumberValue]
        
        let saveRequest = CNSaveRequest()
        saveRequest.addContact(newContact, toContainerWithIdentifier: nil)
        
        let store = CNContactStore()
        do {
            try store.executeSaveRequest(saveRequest)
        } catch {
            print("failed to add contact to address book.")
        }
        
        contact.cellularNumberIdentifier = phoneNumberValue.identifier
        contact.contactIdentifier = newContact.identifier
    }
    
    func updateContact(contact: Contact) {
        
        let newContact = getContact(contact.contactIdentifier)!
        
        newContact.imageData = UIImagePNGRepresentation(contact.image!)
        
        var newPhoneNumbers = [CNLabeledValue]()
        
        
        var phoneNumberUpdated = false
        for phoneNumber in newContact.phoneNumbers {
            if phoneNumber.identifier == contact.cellularNumberIdentifier {
                
                let newPhoneNumber = CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: contact.cellularNumber!))
                contact.cellularNumberIdentifier = newPhoneNumber.identifier
                
                newPhoneNumbers.append(newPhoneNumber)
                
                phoneNumberUpdated = true
            } else {
                newPhoneNumbers.append(phoneNumber)
            }
        }
        
        if !phoneNumberUpdated {
            let newPhoneNumber = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: contact.cellularNumber!))
            contact.cellularNumberIdentifier = newPhoneNumber.identifier
            
            newPhoneNumbers.append(newPhoneNumber)
        }
        
        newContact.phoneNumbers = newPhoneNumbers
        
        let saveRequest = CNSaveRequest()
        saveRequest.updateContact(newContact)
        
        let store = CNContactStore()
        do {
            try store.executeSaveRequest(saveRequest)
        } catch {
            print("failed to update contact to address book.")
        }
    }
}