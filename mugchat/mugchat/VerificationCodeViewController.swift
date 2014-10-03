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

import Foundation

class VerificationCodeViewController: MugChatViewController, VerificationCodeViewDelegate {
    
    private let PLATFORM = "ios"
    private let US_CODE = "+1"
    
    var verificationCodeView: VerificationCodeView!
    var phoneNumber: String!
    var verificationCode: String = "XXXX"
    var retryCount: Int = 0
    
    override func loadView() {
        super.loadView()
        verificationCodeView = VerificationCodeView(phoneNumber: phoneNumber)
        verificationCodeView.delegate = self
        self.view = verificationCodeView
    }
    
    // MARK: - ForgotPasswordViewDelegate Methods
    
    func verificationCodeView(verificatioCodeView: VerificationCodeView!, didFinishTypingVerificationCode verificationCode: String!) {
        if (verificationCode != self.verificationCode) {
            self.retryCount++
            verificationCodeView.resetVerificationCodeField()
            verificationCodeView.showKeyboard()
            if (self.retryCount > 2) {
                self.resendVerificationCode(AuthenticationHelper.sharedInstance.userInSession.id!, deviceId: DeviceHelper.sharedInstance.retrieveDeviceId()!)
            }
        }
    }
    
    func verificationCodeViewDidTapBackButton(verificatioCodeView: VerificationCodeView!) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func verificationCodeViewDidTapResendButton(view: VerificationCodeView!) {
        verificationCodeView.resetVerificationCodeField()
        verificationCodeView.showKeyboard()
        self.resendVerificationCode(AuthenticationHelper.sharedInstance.userInSession.id!, deviceId: DeviceHelper.sharedInstance.retrieveDeviceId()!)
    }
    
    
    // MARK: - Backend Services Integration
    
    private func createDeviceForUser(userId: String, phoneNumber: String, platform: String, token: String) {
        DeviceService.sharedInstance.createDevice(userId,
            phoneNumber: phoneNumber,
            platform: platform,
            uuid: token,
            success: { (device) in
                if (device == nil) {
                    println("Error: Device was not created")
                    return ()
                }
                DeviceHelper.sharedInstance.saveDeviceId(device!.id!)
                self.verificationCode = device!.verificationCode!
                self.retryCount = device!.retryCount!
            },
            failure: { (mugError) in
                println("Error trying to register device: " + mugError!.error!)
        })
    }
    
    private func resendVerificationCode(userId: String, deviceId: String) {
        DeviceService.sharedInstance.resendVerificationCode(userId,
            deviceId: deviceId,
            success: { (device) in
                if (device == nil) {
                    println("Error: Verification Code was not resent")
                    return ()
                }
                self.verificationCode = device!.verificationCode!
                self.retryCount = device!.retryCount!
            },
            failure: { (mugError) in
                println("Error trying to resend verification code to device: " + mugError!.error!)
            })
    }
    
    // MARK: - Required methods
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(phoneNumber: String!) {
        super.init(nibName: nil, bundle: nil)
        self.phoneNumber = phoneNumber
        
        
        let userId = AuthenticationHelper.sharedInstance.userInSession.id!
        let trimmedPhoneNumber = phoneNumber.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let intlPhoneNumber = "\(US_CODE)\(trimmedPhoneNumber)"
        let token = DeviceHelper.sharedInstance.retrieveDeviceToken()!
        
        createDeviceForUser(userId, phoneNumber: intlPhoneNumber, platform: PLATFORM, token: token)
    }
    
}
