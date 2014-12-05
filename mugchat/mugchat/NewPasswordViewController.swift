//
// Copyright 2014 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class NewPasswordViewController: FlipsViewController, NewPasswordViewDelegate {
    
    var newPasswordView: NewPasswordView!
    
    private var username: String!
    private var phoneNumber: String!;
    private var verificationCode: String!
    
    init(username: String, phoneNumber: String, verificationCode: String) {
        super.init(nibName: nil, bundle: nil)
        self.username = username
        self.verificationCode = verificationCode
        self.phoneNumber = phoneNumber
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        newPasswordView = NewPasswordView()
        newPasswordView.delegate = self
        self.view = newPasswordView
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        newPasswordView.viewDidAppear()
}
    
    // MARK: - NewPasswordViewDelegate Methods
    func newPasswordViewDidTapDoneButton(newPassword: NewPasswordView!) {
        UserService.sharedInstance.updatePassword(self.username, phoneNumber: self.phoneNumber, verificationCode: self.verificationCode, newPassword: newPasswordView.passwordField.text!,
            success: { () -> Void in
                println("updatePassword success")
                var loginViewController = LoginViewController()
                self.navigationController?.pushViewController(loginViewController, animated: true)
            }) { (flipError) -> Void in
                println(flipError!.error)
                let alertView = UIAlertView(title: NSLocalizedString("Update Error"), message: flipError!.error, delegate: nil, cancelButtonTitle: LocalizedString.OK)
                alertView.show()
        }
    }
  
    func newPasswordViewDidTapBackButton(newPassword: NewPasswordView!) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
