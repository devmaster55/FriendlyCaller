//
//  ContactViewController.swift
//  ReadFriendlyCaller
//
//  Created by Vedran Ozir on 11/02/16.
//  Modified by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit

class ContactViewController: UIViewController {

    internal var contact: Contact!
    
    @IBOutlet weak var btnChangePassword: UIButton!
    
    
    @IBOutlet weak var image: UIImageView!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        contact.syncToApp()
        
        image.image = contact.image
        
        btnChangePassword.hidden = !contact.isSpecial
    }
    
    @IBAction func didPressPhone(sender: AnyObject) {
        
        print("try to call \(contact.cellularNumber)")
        
        if let cellularNumber = contact.cellularNumber {
            
            let number = cellularNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            let numberString = number.joinWithSeparator("")
            
            if let cellularURL = NSURL(string: "tel://\(numberString)") {
                
                let application:UIApplication = UIApplication.sharedApplication()
                
                if (application.canOpenURL(cellularURL)) {
                    
                    print("calling \(number)")
                    
                    application.openURL(cellularURL);
                    
                } else {
                    
                    print("\(number) cannot be dealed as a Facetime Id")
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressFacetime(sender: AnyObject) {
        
        print("try to make Facetime call \(contact.cellularNumber)")
        
        if let facetimeId = contact.cellularNumber {

            let number = facetimeId.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            let numberString = number.joinWithSeparator("")
            
            if let facetimeURL:NSURL = NSURL(string: "facetime://\(numberString)") {
            
            let application:UIApplication = UIApplication.sharedApplication()
            
            if (application.canOpenURL(facetimeURL)) {
                
                print("calling \(facetimeId)")
                
                application.openURL(facetimeURL);
                
            } else {

                print("\(facetimeId) cannot be dealed as a Facetime Id")
            }
        }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressChangeMasterPassword(sender: AnyObject) {
        MasterUtil.sharedUtil().doSetPassword(self, success: nil)
    }

    @IBAction func didPressEdit(sender: AnyObject) {
        if self.contact.isSpecial == true {
            MasterUtil.sharedUtil().doMasterVerification(self,
                success: { () -> Void in
                    self.performSegueWithIdentifier("SelectedPhotoViewControllerAsEdit", sender: self)
                },
                fail: nil
            )
        } else {
            self.performSegueWithIdentifier("SelectedPhotoViewControllerAsEdit", sender: self)
        }
    }
    @IBAction func didPressRemove(sender: AnyObject) {
        

        self.ask("Do you want to delete this contact?".localized(LangUtil.sharedUtil().getLocale())!,
            message: "",
            closeTitle: "No".localized(LangUtil.sharedUtil().getLocale())!,
            destructiveTitle: "Yes".localized(LangUtil.sharedUtil().getLocale())!,
            destructiveHandler: { (alert) -> Void in
            
            if self.contact.isSpecial == true {
                MasterUtil.sharedUtil().doMasterVerification(self,
                    success: { () -> Void in
                        
                        DIY.showLoading(self, message: "Saving changes...".localized(LangUtil.sharedUtil().getLocale())!, todo: { () in
                            
                            CloudUtil.sharedUtil().deleteImage(self.contact, completion: { (error) in
                                Session.current().remove(self.contact)
                                Session.archive()
                                
                                CloudUtil.sharedUtil().saveContacts({ (error) in
                                    DIY.dismissLoading(self, completion: {
                                        if error != nil {
                                            DIY.alertConnectionError(self)
                                        }else {
                                            self.dismissViewControllerAnimated(true, completion: nil)
                                        }
                                    })
                                })
                            })
                        })
                    },
                    fail: nil
                )
            } else {
                
                DIY.showLoading(self, message: "Saving changes...".localized(LangUtil.sharedUtil().getLocale())!, todo: { () in
                    
                    CloudUtil.sharedUtil().deleteImage(self.contact, completion: { (error) in
                        Session.current().remove(self.contact)
                        Session.archive()
                        
                        CloudUtil.sharedUtil().saveContacts({ (error) in
                            DIY.dismissLoading(self, completion: {
                                if error != nil {
                                    DIY.alertConnectionError(self)
                                }else {
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                }
                            })
                        })
                    })
                })
            }
        })
    }

    @IBAction func didPressClose(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let selectedPhotoViewController = segue.destinationViewController as? SelectedPhotoViewController {
            
            selectedPhotoViewController.contact = contact
            
            selectedPhotoViewController.didAddContact = { () -> Void in
            }
        }
    }
    
    func ask( title: String, message: String, closeTitle: String, destructiveTitle: String, destructiveHandler: ((UIAlertAction) -> Void)?) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: closeTitle, style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: destructiveTitle, style: UIAlertActionStyle.Destructive, handler: destructiveHandler))
        
        presentViewController(alert, animated: true, completion: nil)
    }
}
