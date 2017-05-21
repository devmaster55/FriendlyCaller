//
//  MasterUtil.swift
//  ReadFriendlyCaller
//
//  Created by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit

class MasterUtil : NSObject {
    
    static private var STORE_KEY_MASTER_PWD = "masterPwd"
    static private var STORE_KEY_MASTER_PWD_HINT = "masterPwdHint"
    
    static private var _sharedUtil = MasterUtil()
    
    private var store : NSUserDefaults!
    
    override init() {
        super.init()
        
        store = NSUserDefaults.standardUserDefaults()
    }
    
    class internal func sharedUtil() -> MasterUtil {
        
        return _sharedUtil
    }
    
    func hasSetMasterPassword() -> Bool {

        let old_pwd = getMasterPassword()
        
        return old_pwd != nil
    }
    
    
    private func setMasterPassword(pwd: NSString?) {
        store.setObject(pwd, forKey: MasterUtil.STORE_KEY_MASTER_PWD)
    }
    
    private func getMasterPassword() -> NSString? {
        return store.stringForKey(MasterUtil.STORE_KEY_MASTER_PWD)
    }
    
    private func setMasterPasswordHint(hint: NSString?) {
        store.setObject(hint, forKey: MasterUtil.STORE_KEY_MASTER_PWD_HINT)
    }
    
    private func getMasterPasswordHint() -> NSString? {
        return store.stringForKey(MasterUtil.STORE_KEY_MASTER_PWD_HINT)
    }
    
    func checkMasterPassword(pwd: NSString?) -> Bool {
        
        let old_pwd = getMasterPassword()
        return pwd == old_pwd
    }
    
    func doMasterVerification(targetVC: UIViewController, success: (() -> Void)!, fail : (() -> Void)!) {
        
        let alert = UIAlertController(title: "Master Permission Required".localized(LangUtil.sharedUtil().getLocale()),
                                      message: "Please input master password.".localized(LangUtil.sharedUtil().getLocale()),
                                      preferredStyle: UIAlertControllerStyle.Alert)
        
        // Input Password
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.secureTextEntry = true
            textField.textAlignment = NSTextAlignment.Center
            textField.placeholder = "Password hint:".localized(LangUtil.sharedUtil().getLocale())! + " " + (self.getMasterPasswordHint()! as String) as String
        })

        // OK
        alert.addAction(UIAlertAction(title: "OK".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: {
            action in
            
            let pwd = alert.textFields![0].text

            // Check if password user has input is matching with master password
            
            // if matching, then do sucess()
            if (self.checkMasterPassword(pwd)) {
                if success != nil {

                    success()
                }
                return
            }
            
            // if not, then show warning and do fail()
            let alertMessage = UIAlertController(title: "Warning!".localized(LangUtil.sharedUtil().getLocale()), message: "Invalid Password.".localized(LangUtil.sharedUtil().getLocale()), preferredStyle: .Alert)

            alertMessage.addAction(UIAlertAction(title: "Cancel".localized(LangUtil.sharedUtil().getLocale()), style: .Default, handler: {
                action in
                if fail != nil {
                    fail()
                }
            }))
            targetVC.presentViewController(alertMessage, animated: true, completion: nil)

        }))
        
        // Cancel
        alert.addAction(UIAlertAction(title: "Cancel".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Cancel, handler: {
            action in
            if fail != nil {
                fail()
            }
        }))

        targetVC.presentViewController(alert, animated: true, completion: nil)
    }
    
    func doSetPassword(targetVC: UIViewController, success:(() -> Void)!) {
        doChangePassword(targetVC, old_pwd: "", new_pwd: "", confirm_pwd: "", hint: "", success:success)
    }
    
    private func doChangePassword(targetVC: UIViewController, old_pwd: String, new_pwd: String, confirm_pwd: String, hint: String, success:(() -> Void)!) {

        var alert : UIAlertController
        
        if hasSetMasterPassword() {
            var hint : String = ""
            if self.getMasterPasswordHint()?.length > 0 {
                hint = "Password hint:".localized(LangUtil.sharedUtil().getLocale())! + " " + (self.getMasterPasswordHint()! as String) as String
            }
            
            alert = UIAlertController(title: "Change Master Password".localized(LangUtil.sharedUtil().getLocale()), message: hint.characters.count > 0 ? hint : nil, preferredStyle: UIAlertControllerStyle.Alert)
            
        } else {
            alert = UIAlertController(title: "Set Master Password".localized(LangUtil.sharedUtil().getLocale()), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        }
        
        if self.hasSetMasterPassword() {
            alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "Old password:".localized(LangUtil.sharedUtil().getLocale())
                textField.secureTextEntry = true
                textField.text = old_pwd
                
                textField.textAlignment = NSTextAlignment.Center
            })
        }

        // New Password
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "New password:".localized(LangUtil.sharedUtil().getLocale())
            textField.secureTextEntry = true
            textField.text = new_pwd
            textField.textAlignment = NSTextAlignment.Center
        })

        // Confirm Password
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Confirm password:".localized(LangUtil.sharedUtil().getLocale())
            textField.secureTextEntry = true
            textField.text = confirm_pwd
            textField.textAlignment = NSTextAlignment.Center
        })
        
        // Password Hint
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Password hint:".localized(LangUtil.sharedUtil().getLocale())
            textField.text = hint
            textField.textAlignment = NSTextAlignment.Center
        })
        
        // OK
        alert.addAction(UIAlertAction(title: "OK".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Default, handler: { action in
            var old_password_text = ""
            var new_password_text : String
            var confirm_password_text : String
            var hint_text : String
            
            var index = 0
            if self.hasSetMasterPassword() {
                old_password_text = alert.textFields![index].text!
                index += 1
            }
            new_password_text = alert.textFields![index].text!
            confirm_password_text = alert.textFields![index+1].text!
            hint_text = alert.textFields![index+2].text!
                
            if self.hasSetMasterPassword() {
                if !self.checkMasterPassword(old_password_text) {

                    self.confirm(targetVC,
                        title: "Invalid Old Password".localized(LangUtil.sharedUtil().getLocale()), message: nil,
                        btn_title: "Cancel".localized(LangUtil.sharedUtil().getLocale()),
                        handler: { (Void) -> () in
                            self.doChangePassword(targetVC, old_pwd: "", new_pwd: new_password_text, confirm_pwd: confirm_password_text, hint: hint_text, success: success)
                        }
                    )
                }
            }
            
            if new_password_text == "" {
                self.confirm(targetVC,
                    title: "Invalid New Password".localized(LangUtil.sharedUtil().getLocale()),
                    message: nil,
                    btn_title: "Cancel".localized(LangUtil.sharedUtil().getLocale()),
                    handler: { (Void) -> () in
                    self.doChangePassword(targetVC, old_pwd: old_password_text, new_pwd: "", confirm_pwd: "", hint: hint_text, success: success)
                })
                
                return
            }
            
            if new_password_text != confirm_password_text {
                self.confirm(targetVC,
                    title: "Invalid Confirm Password".localized(LangUtil.sharedUtil().getLocale()),
                    message: nil,
                    btn_title: "Cancel".localized(LangUtil.sharedUtil().getLocale()),
                    handler: { (Void) -> () in
                        self.doChangePassword(targetVC, old_pwd: old_password_text, new_pwd: new_password_text, confirm_pwd: "", hint: hint_text, success: success)
                    }
                )
                
                return
            }
            
            self.setMasterPassword(new_password_text)
            self.setMasterPasswordHint(hint_text)
            self.confirm(targetVC, title: "New password has been set".localized(LangUtil.sharedUtil().getLocale()), message: nil, btn_title: "OK".localized(LangUtil.sharedUtil().getLocale()), handler: { (Void) -> () in
                
                if success != nil {
                    success()
                }
            })

        }))
        
        // Cancel
        alert.addAction(UIAlertAction(title: "Cancel".localized(LangUtil.sharedUtil().getLocale()), style: UIAlertActionStyle.Cancel, handler: { action in
            if !self.hasSetMasterPassword() {
                exit(0)
            }
        }))

        targetVC.presentViewController(alert, animated: true, completion: nil)

    }
    
    func confirm(targetVC: UIViewController, title: String?, message: String?, btn_title: String?, handler: (Void->())!) {
        
        let confirm = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        confirm.addAction(UIAlertAction(title: btn_title, style: .Default, handler: {
            action in
            if handler != nil {
                handler()
            }
        }))
        targetVC.presentViewController(confirm, animated: true, completion: nil)
    }
}