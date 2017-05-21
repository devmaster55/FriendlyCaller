//
//  CloudUtil.swift
//  ReadFriendlyCaller
//
//  Created by Kun.Zhang on 7/6/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//

import UIKit

class CloudUtil : NSObject {
    
    static private var STORE_KEY_TODO_RESTORE = "todo_restore"
    static private var SERVER_URL = "http://ec2-54-194-10-130.eu-west-1.compute.amazonaws.com/ReadFriendlyCaller"
    
    static private var _sharedUtil = CloudUtil()
    
    
    var user_id: String!
    
    private var imageCounter = 0
    
    override init() {
        super.init()
        
    }
    
    class internal func sharedUtil() -> CloudUtil {
     
        return _sharedUtil
    }
    
    func isToDoRestore() -> Bool {
        
        return NSUserDefaults.standardUserDefaults().boolForKey(CloudUtil.STORE_KEY_TODO_RESTORE)
    }
    
    func setToDoRestore(todo: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(todo, forKey: CloudUtil.STORE_KEY_TODO_RESTORE)
    }
    
    func saveContacts(completion: ((error: NSError?) -> Void)? )  {
        
        var contactsValue = [[String: AnyObject]]()
        
        let contacts = Session.current().contacts
        
        for contact in contacts {
            
            let info : [String:AnyObject] = [ "contactIdentifier" : contact.contactIdentifier,
                         "hashId" : contact.hashId,
                         "imageExists" : contact.imageExists,
                         "cellularNumberIdentifier" : contact.cellularNumberIdentifier,
                         "cellularNumber" : contact.cellularNumber!,
                         "isSpecial" : contact.isSpecial]
            
            contactsValue.append(info)
        }
        
        let json = ["contacts": contactsValue]
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            let str = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
            
            let url = NSURL(string: "\(CloudUtil.SERVER_URL)/contact.php?op=set&uid=\(self.user_id)&count=\(contactsValue.count)");
            let request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "POST"
            // insert json data to the request
            request.HTTPBody = "contacts=\(str!)".dataUsingEncoding(NSUTF8StringEncoding)
            
            NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                print("******* response = \(response)")
                
                if error == nil {
                    let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("****** response data = \(responseString!)")
                }
                
                dispatch_async(dispatch_get_main_queue(),{
                    if let completion = completion { completion(error: error) }
                });
                
            }.resume()
            
        } catch let error as NSError {
            dispatch_async(dispatch_get_main_queue(),{
                if let completion = completion { completion(error: error) }
            });
        }

        
        print("app data has been saved on cloud.")
    }
    
    
    
    func uploadImage(contact: Contact, completion: ((storagePath: String?) -> Void)?) {
        
        let myUrl = NSURL(string: "\(CloudUtil.SERVER_URL)/upload.php");
        
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        let param = [
            "uid"    : "\(self.user_id)",
            "hashid" : "\(contact.hashId)"
        ]
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let imageData = UIImageJPEGRepresentation(contact.image!, 0.8)
        
        if(imageData==nil)  {
            if let completion = completion {
                dispatch_async(dispatch_get_main_queue(),{
                    completion(storagePath: nil)
                });
            }
        }
        
        request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            var failed = false
            
            if error == nil {
                print("******* response = \(response)")
                
                // Print out reponse body
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("****** response data = \(responseString!)")
                
                do {
                    _ = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
                } catch {
                    failed = true
                }
            } else{
                failed = true
            }
            
            // You can print out response object
            dispatch_async(dispatch_get_main_queue(),{
                if let completion = completion { completion(storagePath: failed ? nil : "\(self.user_id)/\(contact.hashId).jpg") }
            });
            
        }.resume()
    }
    
    
    func deleteImage(contact: Contact, completion:((error:NSError?) -> Void)?) {
        
        let url = NSURL(string: "\(CloudUtil.SERVER_URL)/delete.php?uid=\(self.user_id)&hashid=\(contact.hashId)");
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {
            (data, response, error) -> Void in
            
            print("******* response = \(response)")
            
            // You can print out response object
            dispatch_async(dispatch_get_main_queue(),{
                if let completion = completion { completion(error: error) }
            });
            
        }).resume()
    }
    
    func getSavedContactsCount(completion: ((contactsCount: Int) -> Void)!) {
        
        let url = NSURL(string: "\(CloudUtil.SERVER_URL)/contact.php?op=get_count&uid=\(self.user_id)");
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: {
            (data, response, error) -> Void in
            
            if error != nil {
                dispatch_async(dispatch_get_main_queue(),{
                    if let completion = completion { completion(contactsCount: -1) }
                });
                return
            }
            
            print("******* response = \(response)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("****** response data = \(responseString!)")
            
            var result = 0
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
                
                if let count = json!["count"] as? String {
                    result = Int(count)!
                }
                
            } catch {
                
            }
            
            dispatch_async(dispatch_get_main_queue(),{
                if let completion = completion { completion(contactsCount: result) }
            });
        }).resume()
    }
    
    func backupAll(progress: ((count:Int, total:Int) -> Void)?, failed: (()->Void)?) {
        
        saveContacts { (error) in
            if error == nil {
                let contacts = Session.current().contacts
                
                self.imageCounter = 0
                
                for contact in contacts {
                    self.uploadImage(contact, completion: { (storagePath) in
                        if storagePath != nil {
                            self.imageCounter += 1
                            if let progress = progress {
                                progress(count: self.imageCounter, total: contacts.count)
                            }
                        }
                    })
                }
            } else {
                dispatch_async(dispatch_get_main_queue(),{
                    if let failed = failed { failed() }
                })
            }
        }
    }
    
    func restoreAll(progress: ((count:Int, total:Int) -> Void)?, completion:((contacts:[Contact]?) -> Void)?) {
        
        let url = NSURL(string: "\(CloudUtil.SERVER_URL)/contact.php?op=get&uid=\(self.user_id)")
        
        NSURLSession.sharedSession().dataTaskWithURL(url!) { (data, response, error) in

            if error != nil {
                dispatch_async(dispatch_get_main_queue(),{
                    if let completion = completion { completion(contacts: nil) }
                });
                return
            }
            
            print("******* response = \(response)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("****** response data = \(responseString!)")
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                
                if let contactsValue = json!["contacts"]!["contacts"] as? [[String:AnyObject]] {
                    
                    var contacts = [Contact]()
                    
                    for contactValue in contactsValue {
                        
                        let contact = Contact()
                        contact.contactIdentifier = contactValue["contactIdentifier"] as! String
                        contact.hashId = contactValue["hashId"] as! Int
                        contact.cellularNumberIdentifier = contactValue["cellularNumberIdentifier"] as! String
                        contact.cellularNumber = contactValue["cellularNumber"] as? String
                        contact.imageExists = false
                        contact.isSpecial = contactValue["isSpecial"] as! Bool
                        
                        contacts.append(contact)
                    }
                    
                    self.imageCounter = 0
                    for contact in contacts {
                        
                        let url = NSURL(string:"\(CloudUtil.SERVER_URL)/uploads/\(self.user_id)/\(contact.hashId).jpg")!
                        
                        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
                            if (error != nil) {
                                // Uh-oh, an error occurred!
                                print("Error downloading image: \(error)")
                            } else {
                                contact.image = UIImage(data: data!)
                                contact.imageExists = true
                            }
                            
                            self.imageCounter += 1
                            dispatch_async(dispatch_get_main_queue(),{
                                if let progress = progress {
                                    progress(count: self.imageCounter, total: contacts.count)
                                }
                            })
                            
                            if (self.imageCounter == contacts.count) {
                                dispatch_async(dispatch_get_main_queue(),{
                                    if let completion = completion { completion(contacts: contacts) }
                                })
                            }
                        }.resume()
                    }
                
                } else {
                    dispatch_async(dispatch_get_main_queue(),{
                        if let completion = completion { completion(contacts: nil) }
                    })
                }
            } catch {
                dispatch_async(dispatch_get_main_queue(),{
                    if let completion = completion { completion(contacts: nil) }
                })
            }
            
        }.resume()
    }
    
    private func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        let filename = "user-profile.jpg"
        
        let mimetype = "image/jpeg"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(imageDataKey)
        body.appendString("\r\n")
        
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(self.user_id)"
    }
    

}

extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
