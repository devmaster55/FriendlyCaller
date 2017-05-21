//
//  ViewController.swift
//  ReadFriendlyCaller
//
//  Created by Vedran Ozir on 03/02/16.
//  Modified by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit
import MobileCoreServices
import ContactsUI

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CNContactPickerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    private var isPickedFromContacts: Bool!
    private var isPickedFromSpecial: Bool!
    private var pickedContact: Contact?
    private var pickedAllNumbers = [CNLabeledValue]()
    
    // MARK: Interface Builder actions
    
    @IBAction func didPressAdd(sender: AnyObject) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "From Your Address Book".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: {
            action in
           
            self.isPickedFromSpecial = false
            
            let controller = CNContactPickerViewController()
            controller.delegate = self
            self.presentViewController(controller, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "New".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: {
            action in
            self.isPickedFromContacts = false
            self.performSegueWithIdentifier("SelectedPhotoViewController", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LangUtil.sharedUtil().getLocale()), style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func dismissAlert() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressSpecial(sender: AnyObject) {
        MasterUtil.sharedUtil().doMasterVerification(self,
            success: { () -> Void in
                
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                
                alert.addAction(UIAlertAction(title: "From Your Address Book".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: {
                    action in
                    
                    self.isPickedFromSpecial = true
                    
                    let controller = CNContactPickerViewController()
                    controller.delegate = self
                    self.presentViewController(controller, animated: true, completion: nil)
                }))
                
                alert.addAction(UIAlertAction(title: "New".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: {
                    action in
                    self.isPickedFromContacts = false
                    self.performSegueWithIdentifier("SelectedPhotoViewControllerAsSpecial", sender: self)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel".localized(LangUtil.sharedUtil().getLocale()), style: .Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
            },
            fail: nil
        )
    }
    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2 + Session.current().normalContacts().count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if indexPath.row == 0 {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("add", forIndexPath: indexPath)
            
            return cell
            
        } else if indexPath.row == 1 {
            
            if let specialContact = Session.current().specialContact() {
            
                specialContact.syncToApp()
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("profile", forIndexPath: indexPath) as! ProfileCell
                
                cell.contact = specialContact
                cell.image.image = specialContact.image
                
                return cell
                
            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("special", forIndexPath: indexPath)
                return cell
            }

        } else {

            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("profile", forIndexPath: indexPath) as! ProfileCell
            
            let contact = Session.current().normalContacts()[indexPath.row-2]
            
            contact.syncToApp()
            
            cell.contact = contact
            cell.image.image = contact.image
            
           return cell
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        
        let src = sourceIndexPath.row
        let dest = destinationIndexPath.row
        
        print("drag&drop", src, dest);
        
        
        if (dest == 0) {
            print("droped at nil");
            
            collectionView.reloadData()
            return
        }
        
        if (src == 1 || dest == 1) && src != dest {
            
            
            print("swap between normal and special");
            
            MasterUtil.sharedUtil().doMasterVerification(
                self,
                
                success: {

                    if Session.current().specialContact() == nil {
                        
                        Session.current().contacts[src - 2].isSpecial = true;
                        
                    } else if (dest == 1) {
                        
                        Session.current().contacts[src - 1].isSpecial = true;
                        Session.current().contacts[0].isSpecial = false;
                        
                    } else {
                        
                        Session.current().contacts[src - 1].isSpecial = false;
                        Session.current().contacts[dest - 1].isSpecial = true;
                        swap(&Session.current().contacts[src - 1], &Session.current().contacts[dest - 1])
                    }
                    
                    Session.current().reorder()
                    
                    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.archiveContactList), userInfo: nil, repeats: false)
                    
                    collectionView.reloadData()
                },
                
                fail: {
                    collectionView.reloadData()
                    
                    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.archiveContactList), userInfo: nil, repeats: false)
                }
            )
            
            return
        }
        
        print("swap between normal contacts");
        
        let delta = Session.current().specialContact() == nil ? 2 : 1
        Session.current().moveContact(src - delta, to: dest - delta)
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.archiveContactList), userInfo: nil, repeats: false)
    }

    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        
        switch(gesture.state) {
            
        case UIGestureRecognizerState.Began:
            guard let selectedIndexPath = self.collectionView.indexPathForItemAtPoint(gesture.locationInView(self.collectionView)) else {
                break
            }
            
            if selectedIndexPath.row == 0 {
                break
            }

            if Session.current().specialContact() == nil && selectedIndexPath.row == 1 {
                break
            }

            // capture reodered array
            
            collectionView.beginInteractiveMovementForItemAtIndexPath(selectedIndexPath)
            
            let cell = self.collectionView.cellForItemAtIndexPath(selectedIndexPath)
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                cell?.frame.origin.y -= 10
                }, completion: { (Bool) -> Void in

                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        cell?.frame.origin.y += 20
                        }, completion: { (Bool) -> Void in

                            UIView.animateWithDuration(0.1, animations: { () -> Void in
                                cell?.frame.origin.y -= 10
                                }, completion: { (Bool) -> Void in
                            })
                    })
            })
            
        case UIGestureRecognizerState.Changed:
            
            let targetIndexPath = self.collectionView.indexPathForItemAtPoint(gesture.locationInView(self.collectionView))
            
            if targetIndexPath?.row != 0 {
                collectionView.updateInteractiveMovementTargetPosition(gesture.locationInView(gesture.view!))
            }
            //print("Gesture - Changed", targetIndexPath?.row)
            
        case UIGestureRecognizerState.Ended:
            print("Gesture - Ended")

            collectionView.endInteractiveMovement()
            
        default:
            print("Gesture - Default")
            collectionView.cancelInteractiveMovement()
        }
    }
    
    func archiveContactList() {
        
//        print ("archiveContactList \(listShaddow)")
        DIY.showLoading(self, message: "Saving changes...".localized(LangUtil.sharedUtil().getLocale())!, todo: { () in
            
            Session.archive()
            CloudUtil.sharedUtil().saveContacts(nil)
            DIY.dismissLoading(self, completion: nil)
        })
    }

    // MARK: UIViewController overrides
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let selectedPhotoViewController = segue.destinationViewController as? SelectedPhotoViewController {
            
            if isPickedFromContacts == true {
                isPickedFromContacts = false
                selectedPhotoViewController.contact = pickedContact
                selectedPhotoViewController.pickedPhoneNumbers = pickedAllNumbers
                
            } else {
                selectedPhotoViewController.contact = Contact()
                selectedPhotoViewController.pickedPhoneNumbers = nil
                
                if segue.identifier == "SelectedPhotoViewControllerAsSpecial" {
                    selectedPhotoViewController.contact.isSpecial = true
                } else {
                    selectedPhotoViewController.contact.isSpecial = false
                }
            }
            
            selectedPhotoViewController.photoChanged = true
            
            selectedPhotoViewController.didAddContact = { () -> Void in
                self.collectionView.reloadData()
            }
            
        }
        
        else if let
            contactViewController = segue.destinationViewController as? ContactViewController,
            sender = sender as? ProfileCell {
                contactViewController.contact = sender.contact
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isPickedFromContacts = false
        isPickedFromSpecial = false
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongGesture(_:)))
        self.collectionView.addGestureRecognizer(longPressGesture)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.reloadData()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let masterUtil = MasterUtil.sharedUtil()
        
        if (!masterUtil.hasSetMasterPassword()) {
            
            LangUtil.sharedUtil().chooseLanguage(self, handler: { (Void) -> () in
                masterUtil.doSetPassword(self, success: { (Void) -> () in
                    CloudUtil.sharedUtil().setToDoRestore(true)
                    
                    self.performSegueWithIdentifier("SettingsViewController", sender: self)
                })
            })
            return
        }
        
        if isPickedFromContacts == true {
            openSelectecdContactWithPicked()
        }
    }
    
    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        print("Canceled picking a contact")
        
        isPickedFromContacts = false;
    }
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        print("Selected a contact")
        
        isPickedFromContacts = true;
        
        // TODO:
        pickedContact = Contact()
        pickedContact?.contactIdentifier = contact.identifier
        if contact.imageData != nil {
            pickedContact!.image = UIImage(data: contact.imageData!)
        }
        if contact.phoneNumbers.count > 0 {
            let phoneNumber = contact.phoneNumbers[0].value as! CNPhoneNumber
            pickedContact!.cellularNumber = phoneNumber.stringValue
            pickedContact!.cellularNumberIdentifier = contact.phoneNumbers[0].identifier
        }
        
        
        pickedContact!.isSpecial = isPickedFromSpecial
        
        
        pickedAllNumbers = contact.phoneNumbers
        
        print(pickedAllNumbers);
        
        /*
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.openSelectecdContactWithPicked), userInfo: nil, repeats: false)
         */
        
        //openSelectecdContactWithPicked()
    }
    
    func openSelectecdContactWithPicked() {
        if isPickedFromSpecial == true {
            self.performSegueWithIdentifier("SelectedPhotoViewControllerAsSpecial", sender: self)
        } else {
            self.performSegueWithIdentifier("SelectedPhotoViewController", sender: self)
        }
    }
    
    /*
    func trial() {
        return
        
        let mmddccyy = NSDateFormatter()
        mmddccyy.timeStyle = .NoStyle
        mmddccyy.dateFormat = "MM/dd/yyyy"
        let d : NSDate = mmddccyy.dateFromString("7/17/2016")!
        
        if NSDate().compare(d) == .OrderedDescending {
            print("expired")
            
            let alert = UIAlertController(title: "Warning", message: "This is a test version and has expired. Please contact developer.", preferredStyle: UIAlertControllerStyle.Alert)
            
            // English
            alert.addAction(UIAlertAction(title: "Got It!", style: UIAlertActionStyle.Default, handler: {
                action in
                exit(0)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
    }*/
    
}

