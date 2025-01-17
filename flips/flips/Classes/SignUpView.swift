//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

class SignUpView : UIView, CustomNavigationBarDelegate, UserFormViewDelegate, MessagesTopViewDelegate {
    
    private let MESSAGES_TOP_VIEW_ANIMATION_DURATION = 0.3
    private var messagesTopView : MessagesTopView!
    internal var navigationBar : CustomNavigationBar!
    internal var userFormView : UserFormView!
    
    weak var delegate : SignUpViewDelegate?
    
    
    // MARK: - Initialization Methods
    
    convenience init() {
        self.init(frame:CGRectZero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initSubviews()
        self.initConstraints()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SignUpView.handlePan(_:)))
        self.messagesTopView.addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func initSubviews() {
        self.backgroundColor = getBackgroundColor()
        
        navigationBar = addCustomNavigationBar()
        navigationBar.setRightButtonEnabled(false)
        navigationBar.delegate = self
        self.addSubview(navigationBar)
        
        messagesTopView = MessagesTopView()
        messagesTopView.delegate = self
        self.addSubview(messagesTopView)
        
        userFormView = UserFormView()
        userFormView.delegate = self
        self.addSubview(userFormView)
    }
    
    internal func addCustomNavigationBar() -> CustomNavigationBar! {
        return CustomNavigationBar.CustomLargeNavigationBar(UIImage(named: "AddProfilePhoto")!, isAvatarButtonInteractionEnabled: true, showBackButton: true, showNextButton: true)
    }
    
    internal func initConstraints() {
        navigationBar.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.trailing.equalTo()(self)
            make.leading.equalTo()(self)
            make.height.equalTo()(self.navigationBar.frame.size.height)
        }
        
        messagesTopView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self.navigationBar.mas_top)
            make.centerX.equalTo()(self.navigationBar)
            make.width.equalTo()(self.navigationBar)
            make.height.equalTo()(self.navigationBar)
        }
        
        userFormView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.navigationBar.mas_bottom)
            make.leading.equalTo()(self)
            make.trailing.equalTo()(self)
        }
    }
    
    // MARK: - Life Cycle
    
    func loadView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpView.dismissKeyboard))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func viewDidAppear() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpView.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpView.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: - CustomNavigationBarDelegate
    
    func customNavigationBarDidTapLeftButton(navBar : CustomNavigationBar) {
        delegate?.signUpViewDidTapBackButton?(self)
    }
    
    func customNavigationBarDidTapRightButton(navBar : CustomNavigationBar) {
        if (userFormView.isAllFieldsValids()) {
            self.dismissKeyboard()
            let userData = getUserData()
            delegate?.signUpView!(self, didTapNextButtonWith: userData.firstName, lastName: userData.lastName, email: userData.email, password: userData.password, birthday: userData.birthday)
        }
    }
    
    func customNavigationBarDidTapAvatarButton(navBar : CustomNavigationBar) {
        delegate?.signUpViewDidTapTakePictureButton(self)
    }
    
    
    // MARK: - UserFormViewDelegate
    
    func userFormView(userFormView: UserFormView, didValidateAllFieldsWithSuccess success: Bool) {
        var hasInvalidFields = false
        
        if (self.userFormView.emailValid) {
            messagesTopView.hideInvalidEmailMessage()
        } else if (self.userFormView.emailFilled) {
            messagesTopView.showInvalidEmailMessage()
            hasInvalidFields = true
        }
        
        if (self.userFormView.passwordValid) {
            messagesTopView.hideInvalidPasswordMessage()
        } else if (self.userFormView.passwordFilled) {
            messagesTopView.showInvalidPasswordMessage()
            hasInvalidFields = true
        }
        
        if (self.userFormView.birthdayValid) {
            messagesTopView.hideInvalidBirthdayMessage()
        } else if (self.userFormView.birthdayFilled) {
            messagesTopView.showInvalidBirthdayMessage()
            hasInvalidFields = true
        }
        
        if (hasInvalidFields) {
            self.showTopMessagesView()
        }
        
        enableRightButton(success)
    }

    func enableRightButton(success: Bool) {
        navigationBar.setRightButtonEnabled(success)
    }
    
    
    // MARK: - Messages Top View methods
    
    func showTopMessagesView() {
        if (self.messagesTopView.frame.origin.y < 0) {
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissKeyboard()
                })
            }
            UIGraphicsBeginImageContextWithOptions(navigationBar.frame.size, false, 0.0)
            navigationBar.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            messagesTopView.setMessagesTopViewBackgroundImage(image)
            
            delegate?.signUpView(self, setStatusBarHidden: true)
            
            self.messagesTopView.layoutIfNeeded()
            UIView.animateWithDuration(self.MESSAGES_TOP_VIEW_ANIMATION_DURATION, animations: { () -> Void in
                self.messagesTopView.mas_makeConstraints({ (make) -> Void in
                    make.removeExisting = true
                    make.top.equalTo()(self)
                    make.bottom.equalTo()(self.navigationBar)
                    make.centerX.equalTo()(self.navigationBar)
                    make.width.equalTo()(self.navigationBar)
                })
                self.messagesTopView.layoutIfNeeded()
            })
        }
    }
    
    func showMissingPictureMessage() {
        self.messagesTopView.showMissingPictureMessage()
        self.showTopMessagesView()
    }
    
    func hideMissingPictureMessage() {
        self.messagesTopView.hideMissingPictureMessage()
    }
    
    
    // MARK: - Actions Handlers
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        let translation = recognizer.translationInView(self)
        let isMessagesTopViewAboveMaximumY = (recognizer.view!.center.y + translation.y) <= (recognizer.view!.frame.size.height/2)
        if (isMessagesTopViewAboveMaximumY) {
            // Don't move to bottom
            recognizer.view!.center = CGPoint(x:recognizer.view!.center.x, y:recognizer.view!.center.y + translation.y)
        }
        
        recognizer.setTranslation(CGPointZero, inView: self)
        
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            self.dismissMessagesTopView()
        }
    }
    
    private func dismissMessagesTopView() {
        delegate?.signUpView(self, setStatusBarHidden: false)
        self.layoutIfNeeded()
        UIView.animateWithDuration(MESSAGES_TOP_VIEW_ANIMATION_DURATION, animations: { () -> Void in
            self.messagesTopView.mas_updateConstraints { (update) -> Void in
                update.removeExisting = true
                update.bottom.equalTo()(self.navigationBar.mas_top)
                update.centerX.equalTo()(self.navigationBar)
                update.width.equalTo()(self.navigationBar)
                update.height.equalTo()(self.navigationBar)
            }
            self.layoutIfNeeded()
        })
    }
    
    // MARK - Keyboard Control
    
    func dismissKeyboard() {
        userFormView.dismissKeyboard()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardMinY = getKeyboardMinY(notification)
        self.slideViews(true, keyboardTop: keyboardMinY)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let keyboardMinY = getKeyboardMinY(notification)
        self.slideViews(false, keyboardTop: keyboardMinY)
    }
    
    private func getKeyboardMinY(notification: NSNotification) -> CGFloat {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardRect: CGRect = userInfo.valueForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue
        return CGRectGetMaxY(self.frame) - CGRectGetHeight(keyboardRect)
    }
    
    func slideViews(movedUp: Bool, keyboardTop: CGFloat) {
        self.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            if (movedUp) {
                let userFormViewFrameBottom = self.userFormView.frame.origin.y + self.userFormView.frame.size.height
                let offsetValue = keyboardTop - userFormViewFrameBottom
                if (offsetValue < 0) {
                    self.navigationBar.mas_makeConstraints { (update) -> Void in
                        update.removeExisting = true
                        update.top.equalTo()(self).with().offset()(offsetValue)
                        update.trailing.equalTo()(self)
                        update.leading.equalTo()(self)
                        update.height.equalTo()(self.navigationBar.frame.size.height)
                    }
                }
            } else {
                self.navigationBar.mas_makeConstraints { (update) -> Void in
                    update.removeExisting = true
                    update.top.equalTo()(self)
                    update.trailing.equalTo()(self)
                    update.leading.equalTo()(self)
                    update.height.equalTo()(self.navigationBar.frame.size.height)
                }
            }
            self.layoutIfNeeded()
        })
    }
    
    // MARK: - MessageTopViewDelegate
    
    func dismissMessagesTopView(messageTopView: MessagesTopView) {
        self.dismissMessagesTopView()
    }
    
    
    // MARK: - Setters
    
    func setUserPicture(picture: UIImage) {
        self.navigationBar.setAvatarImage(picture)
    }
    
    func setUserPictureURL(url: NSURL, success: ((UIImage) -> Void)? = nil) {
        self.navigationBar.setAvatarImageURL(url, success: success)
    }
    
    func setUserData(userData: JSON!) {
        userFormView.setUserData(userData)
    }
    
    func setPasswordFieldVisible(visible: Bool) {
        userFormView.setPasswordFieldVisible(visible)
    }
    
    // MARK: - Getters
    
    func getAvatarImage() -> UIImage! {
        return self.navigationBar.getAvatarImage()
    }
    
    func getBackgroundColor() -> UIColor {
        return UIColor.deepSea()
    }
    
    internal func getUserData() -> (firstName: String, lastName: String, email: String, password: String, birthday:String) {
        return userFormView.getUserData()
    }
}