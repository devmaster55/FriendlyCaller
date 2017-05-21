//
//  SelectedPhotoViewController.swift
//  ReadFriendlyCaller
//
//  Created by Vedran Ozir on 08/02/16.
//  Modified by Ou Yang Shao Bo on 2/23/16.
//  Copyright © 2016 Vedran Ozir. All rights reserved.
//


import UIKit
import Contacts
import MobileCoreServices

extension UIImage {
    
    func hasAlpha() -> Bool {
        let alpha = CGImageGetAlphaInfo(self.CGImage)
        let retVal = (alpha == .First || alpha == .Last || alpha == .PremultipliedFirst || alpha == .PremultipliedLast)
        return retVal
    }
    
    func normalizedImage() -> UIImage {
        if (self.imageOrientation == .Up) {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, !self.hasAlpha(), self.scale)
        var rect = CGRectZero
        rect.size = self.size
        self.drawInRect(rect)
        let retVal = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return retVal
    }
}

class SelectedPhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {

    static let minimalSelectionSize = CGSizeMake(75,75)
    
    enum RectMargin {
        case Left
        case Top
        case Right
        case Bottom
    }
    
    @IBOutlet weak var viewVerticalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!    
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var noPhotoSelectedLabel: UILabel!

    @IBOutlet weak var cornerTopLeft: UIView!
    @IBOutlet weak var cornerTopRight: UIView!
    @IBOutlet weak var cornerBottomRight: UIView!
    @IBOutlet weak var cornerBottomLeft: UIView!
    
    @IBOutlet weak var phoneNumber: UITextField!
    
    
    @IBOutlet weak var btnTakePhoto: UIButton!
    @IBOutlet weak var btnSelectPhotoFromGallery: UIButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBOutlet weak var btnSaveContact: UIButton!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    
    
    internal var contact: Contact!
    internal var pickedPhoneNumbers: [CNLabeledValue]?
    private var phoneNumberHasSelected = false
    
    internal var didAddContact: (() -> Void)?
    
    private var constraints = [UIView: (horizontal: RectMargin, vertical: RectMargin)]()
    private var imageSizeTopLeftConstraint: CGPoint!
    private var imageSizeBottomRightConstraint: CGPoint!
    private var corners: [UIView]!
    
    private var selectionLayer: CAShapeLayer?
    private var selectionLayerRect: CGRect?
    
    private var lastPanPoint = CGPoint()
    private var originalPanOrigin = CGPoint()
    private var originalPanOrigins = [UIView: CGPoint]()
    
    var photoChanged = false
    
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        image.image = contact?.image
        phoneNumber.text = contact?.cellularNumber
        
        phoneNumber.layer.cornerRadius = 10
        phoneNumber.layer.borderColor = UIColor.blueColor().CGColor
        phoneNumber.layer.borderWidth = 1
        
        constraints[cornerTopLeft] = (.Left,.Top)
        constraints[cornerTopRight] = (.Right,.Top)
        constraints[cornerBottomRight] = (.Right,.Bottom)
        constraints[cornerBottomLeft] = (.Left,.Bottom)
        
        corners = [cornerTopLeft, cornerTopRight, cornerBottomRight, cornerBottomLeft]
        
     
        // Locaizing
        btnTakePhoto.setTitle("Take Photo".localized(LangUtil.sharedUtil().getLocale()),
            forState: UIControlState.Normal)
        
        btnSelectPhotoFromGallery.setTitle("Select from Gallery".localized(LangUtil.sharedUtil().getLocale()),
            forState: UIControlState.Normal)
        
        btnCrop.setTitle("Crop".localized(LangUtil.sharedUtil().getLocale()),
            forState: UIControlState.Normal)
        
        btnSaveContact.setTitle("SAVE CONTACT".localized(LangUtil.sharedUtil().getLocale()),
            forState: UIControlState.Normal)
        
        lblPhoneNumber.text = "Enter Phone Number".localized(LangUtil.sharedUtil().getLocale())
        
        noPhotoSelectedLabel.text = "No Photo selected".localized(LangUtil.sharedUtil().getLocale())
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        for corner in corners {
            
            corner.layer.cornerRadius = 22 / 2
            corner.layer.borderColor = UIColor.whiteColor().CGColor
            corner.layer.borderWidth = 1
        }
        
        if pickedPhoneNumbers != nil && phoneNumberHasSelected == false {
            if pickedPhoneNumbers?.count == 0 {
                phoneNumberHasSelected = false
                return
            }
            
            if pickedPhoneNumbers?.count == 1 {
                phoneNumberHasSelected = true
                return
            }
            
            let alert = UIAlertController(title: "Choose Phone Number".localized(LangUtil.sharedUtil().getLocale()), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            
            for number in pickedPhoneNumbers! {
                
                alert.addAction(UIAlertAction(title: (number.value as! CNPhoneNumber).stringValue, style: UIAlertActionStyle.Default, handler: {
                    action in
                    self.phoneNumber.text = (number.value as! CNPhoneNumber).stringValue
                    self.phoneNumberHasSelected = true
                    self.contact.cellularNumberIdentifier = number.identifier
                }))
            }

            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        initializeSelectionPointPositions()
        
        if selectionLayer == nil ||
            selectionLayerRect != image.bounds  {
                
                redrawSelectionLayer()
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func didPressTakePhoto(sender: AnyObject) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
        imagePickerController.delegate = self
        
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        self.presentViewController(imagePickerController,
            animated: true) { () -> Void in
        }
    }

    @IBAction func didPressSelectFromGallery(sender: AnyObject) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePickerController.delegate = self
        
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        self.presentViewController(imagePickerController,
            animated: true) { () -> Void in
        }
    }

    @IBAction func didPressCrop(sender: AnyObject) {
        
        if let originImage = self.image.image where imageSizeTopLeftConstraint != nil {
    
            let imageSize = CGSizeMake(imageSizeBottomRightConstraint.x - imageSizeTopLeftConstraint.x,
                                        imageSizeBottomRightConstraint.y - imageSizeTopLeftConstraint.y)
            
            let topLeft = CGPointMake(
                originImage.size.width * (cornerTopLeft.center.x - imageSizeTopLeftConstraint.x) / imageSize.width,
                originImage.size.height * (cornerTopLeft.center.y - imageSizeTopLeftConstraint.y) / imageSize.height)
            
            let rightBottom = CGPointMake(
                originImage.size.width * (cornerBottomRight.center.x - imageSizeTopLeftConstraint.x) / imageSize.width,
                originImage.size.height * (cornerBottomRight.center.y - imageSizeTopLeftConstraint.y) / imageSize.height)
            
            let rect: CGRect = CGRectMake(topLeft.x, topLeft.y, rightBottom.x - topLeft.x, rightBottom.y - topLeft.y)

            // Create a new image based on the imageRef and rotate back to the original orientation
            let imageN = originImage.normalizedImage()
            
            let imageRef: CGImageRef = CGImageCreateWithImageInRect(imageN.CGImage, rect)!
            
            let image = UIImage(CGImage: imageRef)
            
            self.image.image = image

            // initializeSelectionPointPositions
            
            imageSizeTopLeftConstraint = nil
            initializeSelectionPointPositions()
            
            redrawSelectionLayer()
            
            photoChanged = true
        }
    }
    
    @IBAction func didPressAddContact(sender: AnyObject) {
        if self.phoneNumber.text?.characters.count == 0 {
            return
        }
        
        if let contact = contact where image.image != nil {
            
            DIY.showLoading(self, message: "Saving changes...".localized(LangUtil.sharedUtil().getLocale())!, todo: { () in
                
                self.contact.image = self.image.image
                self.contact.cellularNumber = self.phoneNumber.text
                
                self.contact.syncToAddressBook()
                
                Session.current().addOrUpdate(contact)
                Session.archive()
                
                self.didAddContact?()
                
                CloudUtil.sharedUtil().saveContacts({ (error) in
                    if error != nil {
                        DIY.dismissLoading(self, completion: {
                            DIY.alertConnectionError(self)
                        })
                    } else {
                        if self.photoChanged {
                            CloudUtil.sharedUtil().uploadImage(contact, completion: { (storagePath) in
                                DIY.dismissLoading(self, completion: {
                                    if storagePath == nil {
                                        DIY.alertConnectionError(self)
                                    } else {
                                        self.dismissViewControllerAnimated(true, completion: nil)
                                    }
                                })
                            })
                        } else {
                            DIY.dismissLoading(self, completion: {
                                self.dismissViewControllerAnimated(true, completion: nil)
                            })
                        }
                    }
                })
            })
        }
    }
    
    @IBAction func didPressClose(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPanCorner(sender: UIPanGestureRecognizer) {
        
        if let
            corner = sender.view,
            constraint = constraints[corner] {
        
            switch sender.state {
                
            case .Began:
                
                lastPanPoint = sender.translationInView(self.view)
                originalPanOrigin = corner.center
                
            case .Changed:
                
                if imageSizeTopLeftConstraint != nil {
                    
                    // save originalCornerCenters
                    
                    var originalCornerCenters = [UIView: CGPoint]()
                    
                    for corner in corners {
                        originalCornerCenters[corner] = corner.center
                    }

                    // get translation
                    
                    let originalTranslation = sender.translationInView(self.view)
                    let translation = CGPoint(x: originalTranslation.x - lastPanPoint.x, y: originalTranslation.y - lastPanPoint.y)
                    
                    var newOrigin = originalPanOrigin
                    
                    newOrigin.x += translation.x
                    newOrigin.y += translation.y
                    
                    var constraintsToApplyHorizontal = 1
                    var constraintsToApplyVertical = 1
                    
                    if constraint.horizontal == .Left {
                        
                        if newOrigin.x >= imageSizeTopLeftConstraint.x {
                            
                            constraintsToApplyHorizontal -= 1
                        }
                        
                    }

                    if constraint.horizontal == .Right {
                        
                        if newOrigin.x <= imageSizeBottomRightConstraint.x {
                            
                            constraintsToApplyHorizontal -= 1
                        }
                        
                    }
                    
                    if constraint.vertical == .Top {
                        
                        if newOrigin.y >= imageSizeTopLeftConstraint.y {
                            
                            constraintsToApplyVertical -= 1
                        }
                    }
                    
                    if constraint.vertical == .Bottom {
                        
                        if newOrigin.y <= imageSizeBottomRightConstraint.y {
                            
                            constraintsToApplyVertical -= 1
                        }
                    }
                    
                    // set new dragging corner center
                    
                    corner.center.x = newOrigin.x
                    corner.center.y = newOrigin.y

                    // move 2 related points
                    
                    for (cornerWalk, constraintWalk) in constraints {
                        
                        if constraintWalk.horizontal == constraint.horizontal && cornerWalk !== corner {
                            
                            // found related corner
                            
                            cornerWalk.center.x = corner.center.x
                        }
                    
                        if constraintWalk.vertical == constraint.vertical && cornerWalk !== corner {
                            
                            // found related corner
                            
                            cornerWalk.center.y = corner.center.y
                        }
                    }
                    
                    // check for minimal selection size
                    
                    var undo = (horizontal: false, vertical: false)
                    
                    let selectionSize = CGRectMake(cornerTopLeft.center.x,
                                                    cornerTopLeft.center.y,
                                                    cornerBottomRight.center.x - cornerTopLeft.center.x,
                                                    cornerBottomRight.center.y - cornerTopLeft.center.y)
                    
                    if constraintsToApplyHorizontal > 0 || selectionSize.size.width < SelectedPhotoViewController.minimalSelectionSize.width {

                        // undo horizontal change
                        
                        undo.horizontal = true
                    }
                    
                    if constraintsToApplyVertical > 0 || selectionSize.size.height < SelectedPhotoViewController.minimalSelectionSize.height {
                        
                        // undo vertical change
                        
                        undo.vertical = true
                    }
                    
                    // if it is undeo case, undo all corners
                    
                    for corner in corners {
                        
                        if let originalCornerCenter = originalCornerCenters[corner] {
                            
                            if undo.horizontal {
                                
                                corner.center.x = originalCornerCenter.x
                            }
                            
                            if undo.vertical {
                                
                                corner.center.y = originalCornerCenter.y
                            }
                        }
                    }
                    
                    redrawSelectionLayer()
                }
                
            default: break
            }
        }
    }
    
    @IBAction func didPanImage(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
        case .Began:
            
            lastPanPoint = sender.translationInView(self.view)
            
            for corner in corners {
                originalPanOrigins[corner] = corner.center
            }
            
        case .Changed:
            
            if imageSizeTopLeftConstraint != nil {
                
                // save originalCornerCenters
                
                var originalCornerCenters = [UIView: CGPoint]()
                
                for corner in corners {
                    originalCornerCenters[corner] = corner.center
                }
                
                // get translation
                
                let originalTranslation = sender.translationInView(self.view)
                let translation = CGPoint(x: originalTranslation.x - lastPanPoint.x, y: originalTranslation.y - lastPanPoint.y)
                
                for corner in corners {
                    
                    if let originalPanOrigin = originalPanOrigins[corner] {
                        
                        corner.center = originalPanOrigin
                        
                        corner.center.x += translation.x
                        corner.center.y += translation.y
                    }
                }
                
                // for all of 4 corners
                
                var constraintsToApplyHorizontal = 4 * 1
                var constraintsToApplyVertical = 4 * 1
                
                for corner in corners {
                    
                    if let constraint = constraints[corner] {
                        
                        if constraint.horizontal == .Left {
                            
                            if corner.center.x >= imageSizeTopLeftConstraint.x {
                                
                                constraintsToApplyHorizontal -= 1
                            }
                            
                        }
                        
                        if constraint.horizontal == .Right {
                            
                            if corner.center.x <= imageSizeBottomRightConstraint.x {
                                
                                constraintsToApplyHorizontal -= 1
                            }
                            
                        }
                        
                        if constraint.vertical == .Top {
                            
                            if corner.center.y >= imageSizeTopLeftConstraint.y {
                                
                                constraintsToApplyVertical -= 1
                            }
                        }
                        
                        if constraint.vertical == .Bottom {
                            
                            if corner.center.y <= imageSizeBottomRightConstraint.y {
                                
                                constraintsToApplyVertical -= 1
                            }
                        }
                    }
                }
                
                // check for minimal selection size
                
                var undo = (horizontal: false, vertical: false)
                
                if constraintsToApplyHorizontal > 0 {
                    
                    // undo horizontal change
                    
                    undo.horizontal = true
                }
                
                if constraintsToApplyVertical > 0 {
                    
                    // undo vertical change
                    
                    undo.vertical = true
                }
                
                // if it is undeo case, undo all corners
                
                for corner in corners {
                    
                    if let originalCornerCenter = originalCornerCenters[corner] {
                        
                        if undo.horizontal {
                            
                            corner.center.x = originalCornerCenter.x
                        }
                        
                        if undo.vertical {
                            
                            corner.center.y = originalCornerCenter.y
                        }
                    }
                }
                
                redrawSelectionLayer()
            }
            
        default: break
        }
    }
    
    // MARK: Utility functions
    
    func initializeSelectionPointPositions() {

        if imageSizeTopLeftConstraint == nil {
            
            if let image = image.image {
                
                self.view.layoutIfNeeded()
                
                let aspectRatio = image.size.width / image.size.height
                
                if aspectRatio > 1.0 {
                    
                    let width = self.image.frame.size.width
                    let height = width / aspectRatio
                    
                    imageSizeTopLeftConstraint = CGPoint()
                    imageSizeTopLeftConstraint.x = self.image.frame.origin.x
                    imageSizeTopLeftConstraint.y = self.image.center.y - height/2
                    
                    imageSizeBottomRightConstraint = CGPoint()
                    imageSizeBottomRightConstraint.x = self.image.frame.origin.x + width
                    imageSizeBottomRightConstraint.y = self.image.center.y + height/2
                }
                    
                else {
                    
                    let height = self.image.frame.size.height
                    let width = height * aspectRatio
                    
                    imageSizeTopLeftConstraint = CGPoint()
                    imageSizeTopLeftConstraint.y = self.image.frame.origin.y
                    imageSizeTopLeftConstraint.x = self.image.center.x - width/2
                    
                    imageSizeBottomRightConstraint = CGPoint()
                    imageSizeBottomRightConstraint.y = self.image.frame.origin.y + height
                    imageSizeBottomRightConstraint.x = self.image.center.x + width/2
                }
                
                cornerTopLeft.center = imageSizeTopLeftConstraint
                cornerTopRight.center = CGPointMake(imageSizeBottomRightConstraint.x, imageSizeTopLeftConstraint.y)
                cornerBottomRight.center = imageSizeBottomRightConstraint
                cornerBottomLeft.center = CGPointMake(imageSizeTopLeftConstraint.x, imageSizeBottomRightConstraint.y)
                
                cornerTopLeft.hidden = false
                cornerTopRight.hidden = false
                cornerBottomRight.hidden = false
                cornerBottomLeft.hidden = false
                
                noPhotoSelectedLabel.hidden = true
                
            } else {
                
                cornerTopLeft.hidden = true
                cornerTopRight.hidden = true
                cornerBottomRight.hidden = true
                cornerBottomLeft.hidden = true
                
                noPhotoSelectedLabel.hidden = false
            }
            
        }

    }
    
    func redrawSelectionLayer() {

        selectionLayer?.removeFromSuperlayer()
        
        if let imageSizeTopLeftConstraint = imageSizeTopLeftConstraint {
            
            selectionLayer = CAShapeLayer()
            selectionLayerRect = CGRectMake( imageSizeTopLeftConstraint.x - image.frame.origin.x,
                                            imageSizeTopLeftConstraint.y - image.frame.origin.y,
                                            imageSizeBottomRightConstraint.x - imageSizeTopLeftConstraint.x,
                                            imageSizeBottomRightConstraint.y - imageSizeTopLeftConstraint.y)
            
            let outerPath = UIBezierPath(rect: selectionLayerRect!)
            
            let circlePath = UIBezierPath(roundedRect:
                                CGRectMake( cornerTopLeft.center.x - image.frame.origin.x,
                                            cornerTopLeft.center.y - image.frame.origin.y,
                                            cornerBottomRight.center.x - cornerTopLeft.center.x,
                                            cornerBottomRight.center.y - cornerTopLeft.center.y),
                                cornerRadius: 0)
            
            outerPath.appendPath(circlePath)
            
            if let selectionLayer = selectionLayer {
                selectionLayer.path = outerPath.CGPath
                selectionLayer.fillRule = kCAFillRuleEvenOdd
                selectionLayer.fillColor = UIColor.blackColor().CGColor
                selectionLayer.opacity = 0.75
                
                image.layer.addSublayer(selectionLayer)
            }
        } else {
            selectionLayer = nil
        }

    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        image.image = info [ UIImagePickerControllerOriginalImage ] as? UIImage
        
        // initializeSelectionPointPositions
        
        imageSizeTopLeftConstraint = nil
        initializeSelectionPointPositions()
        
        redrawSelectionLayer()
        
        photoChanged = true
        
        self.dismissViewControllerAnimated(true,
            completion: { () -> Void in
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        self.dismissViewControllerAnimated(true,
            completion: { () -> Void in
        })
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        viewVerticalConstraint.constant -= 200
        self.view.layoutIfNeeded()
        
        scrollView.setContentOffset(CGPointMake(0, 200), animated: true)
        
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        
        viewVerticalConstraint.constant += 200
        self.view.layoutIfNeeded()
        
        scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}
