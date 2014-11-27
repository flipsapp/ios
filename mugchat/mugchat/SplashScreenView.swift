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
    
    var delegate: SplashScreenViewDelegate?
    
    private let MARGIN_RIGHT:CGFloat = 40.0
    private let MARGIN_LEFT:CGFloat = 40.0
    private let MUGCHAT_WORD_LOGO_MARGIN_TOP: CGFloat = 15.0
    
    private var logoView: UIView!
    private var bubbleChatImageView: UIImageView!
    private var mugchatWordImageView: UIImageView!
    
    // MARK: - Required inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        self.backgroundColor = UIColor.redColor()
        self.addSubviews()
        self.makeConstraints()
    }
    
    func addSubviews() {
        
        logoView = UIView()
        self.addSubview(logoView)
        
        bubbleChatImageView = UIImageView(image: UIImage(named: "ChatBubble"))
        bubbleChatImageView.sizeToFit()
        bubbleChatImageView.contentMode = UIViewContentMode.Center
        logoView.addSubview(bubbleChatImageView)
        
        mugchatWordImageView = UIImageView(image: UIImage(named: "MugChatWord"))
        mugchatWordImageView.sizeToFit()
        mugchatWordImageView.contentMode = UIViewContentMode.Center
        logoView.addSubview(mugchatWordImageView)
    }
    
    func makeConstraints() {
        
        logoView.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self)
            make.centerY.equalTo()(self)
            make.left.equalTo()(self).with().offset()(self.MARGIN_LEFT)
            make.right.equalTo()(self).with().offset()(-self.MARGIN_RIGHT)
            make.top.equalTo()(self.bubbleChatImageView)
            make.bottom.equalTo()(self.mugchatWordImageView)
        }
        
        bubbleChatImageView.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.logoView)
            make.top.equalTo()(self.logoView)
            make.height.equalTo()(self.bubbleChatImageView.frame.size.height)
            make.left.equalTo()(self.logoView)
            make.right.equalTo()(self.logoView)
        }
        
        mugchatWordImageView.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.logoView)
            make.top.equalTo()(self.bubbleChatImageView.mas_bottom).with().offset()(self.MUGCHAT_WORD_LOGO_MARGIN_TOP)
            make.left.equalTo()(self.logoView)
            make.right.equalTo()(self.logoView)
            make.bottom.equalTo()(self.logoView)
            make.height.equalTo()(self.mugchatWordImageView.frame.height)
        }

    }

}

protocol SplashScreenViewDelegate {
    
}

