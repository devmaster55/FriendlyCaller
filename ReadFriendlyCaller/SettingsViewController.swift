//
//  SettingsViewController.swift
//  ReadFriendlyCaller
//
//  Created by Kun.Zhang on 6/20/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var englishCell: UITableViewCell!
    @IBOutlet weak var arabicCell: UITableViewCell!
    @IBOutlet weak var spanishCell: UITableViewCell!
    @IBOutlet weak var frenchCell: UITableViewCell!
    
    @IBOutlet weak var backupCell: UITableViewCell!
    @IBOutlet weak var restoreCell: UITableViewCell!
    
    @IBOutlet weak var backupLabel: UILabel!
    @IBOutlet weak var restoreLabel: UILabel!
    @IBOutlet weak var restoreIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressStatusLabel: UILabel!

    
    private var restorableContactsCount : Int = -1
    
    override func viewDidLoad() {
        onChangeLanguage()
        
        progressContainer.hidden = true
        
        backupLabel.text = "Backup".localized(LangUtil.sharedUtil().getLocale())! + " (\(Session.current().contacts.count))"
        
        restoreCell.userInteractionEnabled = false
        restoreLabel.text = "Restore".localized(LangUtil.sharedUtil().getLocale())
        restoreIndicator.startAnimating()
        restoreIndicator.hidesWhenStopped = true
        
        CloudUtil.sharedUtil().getSavedContactsCount { (contactsCount) in
            
            if contactsCount == -1 {
                DIY.alertConnectionError(self)
            }
            
            self.restoreLabel.text = "Restore".localized(LangUtil.sharedUtil().getLocale())! + " (\(max(contactsCount, 0)))"
            if contactsCount > 0 {
                self.restoreCell.userInteractionEnabled = true
            }
            self.restoreIndicator.stopAnimating()
            self.tableView.reloadData()
            
            
            self.restorableContactsCount = max(contactsCount, 0)
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Language".localized(LangUtil.sharedUtil().getLocale())
        }
        if section == 1 {
            return "Backup & Restore".localized(LangUtil.sharedUtil().getLocale())
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == 0 {
            
            switch indexPath.row {
                
            case 0:
                LangUtil.sharedUtil().setLocale("en")
                break
                
            case 1:
                LangUtil.sharedUtil().setLocale("ar")
                break
                
            case 2:
                LangUtil.sharedUtil().setLocale("es")
                break
            
            case 3:
                LangUtil.sharedUtil().setLocale("fr")
                break
            
            default:
                break
            }
            
            onChangeLanguage()
        }
        else if indexPath.section == 1 {
            switch indexPath.row {
                
            case 0:
                onBackup()
                break
                
            case 1:
                onRestore()
                break
                
            default:
                break
            }
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func onBackup() {
        self.progressContainer.alpha = 0
        self.progressBar.progress = 0
        self.progressStatusLabel.text = "0/\(self.restorableContactsCount)"
        self.progressContainer.hidden = false
        
        UIView.animateWithDuration(0.5, animations: {
            self.progressContainer.alpha = 1
        })
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        CloudUtil.sharedUtil().backupAll({ (count, total) in
            self.progressBar.progress = Float(count) / Float(total)
            self.progressStatusLabel.text = "\(count)/\(total)"
            
            if count == total {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                UIView.animateWithDuration(0.5, animations: {
                    self.progressContainer.alpha = 0
                })
                
                
            }
            
            self.restoreLabel.text = "Restore".localized(LangUtil.sharedUtil().getLocale())! + " (\(count))"
            self.restoreCell.userInteractionEnabled = count > 0
            
        }, failed: { Void in
            DIY.alertConnectionError(self)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            UIView.animateWithDuration(0.5, animations: {
                self.progressContainer.alpha = 0
            })
        })
    }
    
    func onRestore() {
        DIY.ask(self,
                title: "Restore old contacts?".localized(LangUtil.sharedUtil().getLocale()),
                message: nil,
                
                btn_yes: "Yes".localized(LangUtil.sharedUtil().getLocale()),
                yes_handler: { (Void) -> () in
                    
                    self.progressContainer.alpha = 0
                    
                    self.progressBar.progress = 0
                    self.progressStatusLabel.text = "0/\(self.restorableContactsCount)"
                    self.progressContainer.hidden = false
                    
                    UIView.animateWithDuration(0.5, animations: {
                        self.progressContainer.alpha = 1
                    })
                    
                    CloudUtil.sharedUtil().restoreAll({ (count, total) in
                        
                        self.progressBar.progress = Float(count) / Float(total)
                        self.progressStatusLabel.text = "\(count)/\(total)"
                        
                        if count == total {
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        }                        
                    }, completion: {(contacts) in
                        if let contacts = contacts {
                            
                            for contact in contacts {
                                contact.syncToAddressBook()
                            }
                            
                            Session.current().contacts = contacts
                            Session.archive()
                        } else {
                            DIY.alertConnectionError(self)
                        }
                        
                        UIView.animateWithDuration(0.5, animations: {
                            self.progressContainer.alpha = 0
                        })
                    })
            }, btn_no: "No".localized(LangUtil.sharedUtil().getLocale()),no_handler: nil)
    }
    
    func onChangeLanguage() {
        backButton.setTitle("Settings".localized(LangUtil.sharedUtil().getLocale()), forState: .Normal)
        backButton.setTitle("Settings".localized(LangUtil.sharedUtil().getLocale()), forState: .Highlighted)
        
        englishCell.accessoryType = LangUtil.sharedUtil().getLocale() == "en" ? .Checkmark : .None
        arabicCell.accessoryType = LangUtil.sharedUtil().getLocale() == "ar" ? .Checkmark : .None
        spanishCell.accessoryType = LangUtil.sharedUtil().getLocale() == "es" ? .Checkmark : .None
        frenchCell.accessoryType = LangUtil.sharedUtil().getLocale() == "fr" ? .Checkmark : .None
        
        backupLabel.text = "Backup".localized(LangUtil.sharedUtil().getLocale())! + " (\(Session.current().contacts.count))"
        if restorableContactsCount < 0 {
            restoreLabel.text = "Restore".localized(LangUtil.sharedUtil().getLocale())
        } else {
            restoreLabel.text = "Restore".localized(LangUtil.sharedUtil().getLocale())! + " (\(restorableContactsCount))"
        }
        
        tableView.reloadData()
        
    }
    
    @IBAction func didPressBack(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
}