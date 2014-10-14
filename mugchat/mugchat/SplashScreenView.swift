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

class SplashScreenView: UIView {
    
    var backgroundImage: UIImageView!
    var delegate: SplashScreenViewDelegate?
    
    override init() {
        super.init()
        self.addSubviews()
        self.makeConstraints()
    }
    
    func viewWillAppear() {
        if (FBSession.activeSession().state == FBSessionState.CreatedTokenLoaded) {
            self.delegate?.splashScreenViewAttemptLoginWithFacebook(self)
        } else {
            self.delegate?.splashScreenViewAttemptLogin(self)
        }
        
    }
    
    func addSubviews() {
        self.backgroundImage = UIImageView(image: UIImage(named: "SplashScreen"))
        self.backgroundImage.contentMode = UIViewContentMode.ScaleToFill
        self.addSubview(self.backgroundImage)
    }
    
    func makeConstraints() {
        backgroundImage.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self)
            make.centerY.equalTo()(self)
            make.height.equalTo()(self)
            make.width.equalTo()(self)
        }
    }
    
    
    // MARK: - Required inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol SplashScreenViewDelegate {
    func splashScreenViewAttemptLoginWithFacebook(sender: SplashScreenView)
    func splashScreenViewAttemptLogin(sender: SplashScreenView)
}