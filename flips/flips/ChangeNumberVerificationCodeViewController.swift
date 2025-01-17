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

import Foundation

class ChangeNumberVerificationCodeViewController: VerificationCodeViewController, ChangeNumberVerificationCodeViewDelegate {
 
    private var changeNumberVerificationCodeView: ChangeNumberVerificationCodeView!
    
    override func loadView() {
        changeNumberVerificationCodeView = ChangeNumberVerificationCodeView(phoneNumber: self.phoneNumber)
        changeNumberVerificationCodeView.delegate = self
        changeNumberVerificationCodeView.verificationCodeDelegate = self
        
        self.view = changeNumberVerificationCodeView
    }
    
    override func viewWillAppear(animated: Bool) {
        changeNumberVerificationCodeView.viewWillAppear()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        changeNumberVerificationCodeView.viewWillDisappear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWhiteNavBarWithBackButton("Verification Code")
    }
    
    // MARK: - ChangeNumberVerificationCodeViewDelegate
    
    func makeConstraintToNavigationBarBottom(view: UIView!) {
        view.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.mas_topLayoutGuideBottom)
            return ()
        }
    }
    
    func navigateAfterValidateDevice() {
        for viewController in self.navigationController!.viewControllers {
            
            let lastViewController = viewController 
            if (lastViewController.isKindOfClass(SettingsViewController.self)) {
                self.navigationController?.popToViewController(lastViewController, animated: true)
                break
            }
        }
    }
    
    override func verificationCodeViewDidTapResendButton(view: VerificationCodeView!) {
        view.resetVerificationCodeField()
        view.focusKeyboardOnCodeField()
        
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        
        UserService.sharedInstance.resendCodeWhenChangingNumber(phoneNumber.intlPhoneNumberWithCountryCode(self.countryCode),
            success: { (device) -> Void in
                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
            },
            failure: { (flipError) -> Void in
                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                let alertView = UIAlertView(title: NSLocalizedString("Error when trying to resend verification code"), message: flipError?.details, delegate: self, cancelButtonTitle: LocalizedString.OK)
                alertView.show()
            }
        )
    }

}
