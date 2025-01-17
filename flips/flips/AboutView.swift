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

import UIKit

class AboutView: UIView, CustomNavigationBarDelegate {
    
    weak var delegate: AboutViewDelegate?
    
    private let LOGO_CONTAINER_HEIGHT: CGFloat = 320.0
    private let MINIMAL_SPACE_BETWEEN_VIEWS: CGFloat = 10.0
    private let COPYRIGHT_HEIGHT: CGFloat = 60.0
    
    private var navigationBar: CustomNavigationBar!
    
    private var logoContainer: UIView!
    private var flipsLogo: UIImageView!
    private var flipsWord: UIImageView!
    private var copyright: UILabel!
    private var webView: FlipsWebView!
    
    init() {
        super.init(frame: CGRectZero)
        self.addSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews();
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewDidLoad() {
        self.makeConstraints()
        webView.viewDidLoad()
    }

    // MARK: - Required inits

    private func addSubviews() {
        
        self.backgroundColor = UIColor.flipOrange()
        
        navigationBar = CustomNavigationBar.CustomSmallNavigationBar("", showBackButton: true)
        navigationBar.delegate = self
        self.addSubview(navigationBar)
        
        logoContainer = UIView()
        self.addSubview(logoContainer)
        
        flipsLogo = UIImageView(image: UIImage(named: "ChatBubble"))
        flipsLogo.sizeToFit()
        self.logoContainer.addSubview(flipsLogo)
        
        flipsWord = UIImageView(image: UIImage(named: "FlipWord"))
        flipsWord.sizeToFit()
        self.logoContainer.addSubview(flipsWord)
        
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(NSCalendarUnit.Year, fromDate: currentDate)
        
        let build = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
        
        copyright = UILabel()
        copyright.numberOfLines = 3
        copyright.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h6)
        copyright.sizeToFit()
        copyright.text = "Copyright © \(components.year) Flips.\nAll Rights Reserved.\nv\(build)"
        copyright.textColor = UIColor.whiteColor()
        copyright.textAlignment = NSTextAlignment.Center
        self.logoContainer.addSubview(copyright)
        
        let HOST = AppSettings.currentSettings().serverURL()
        
        webView = FlipsWebView(URL: "\(HOST)/about")
        self.addSubview(webView)
    }
    
    func makeConstraints() {
        
        navigationBar.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.trailing.equalTo()(self)
            make.leading.equalTo()(self)
            make.height.equalTo()(self.navigationBar.frame.size.height)
        }
        
        logoContainer.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.navigationBar.mas_bottom)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.LOGO_CONTAINER_HEIGHT)
        }
        
        flipsLogo.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.logoContainer)
            make.centerX.equalTo()(self.logoContainer)
            
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.width.equalTo()(self.flipsLogo.frame.size.width * 2 / 3)
                make.height.equalTo()(self.flipsLogo.frame.size.height * 2 / 3)
            } else {
                make.width.equalTo()(self.flipsLogo.frame.size.width)
                make.height.equalTo()(self.flipsLogo.frame.size.height)
            }
        }
        
        flipsWord.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.flipsLogo.mas_bottom).with().offset()(self.MINIMAL_SPACE_BETWEEN_VIEWS)
            make.centerX.equalTo()(self)
            
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.width.equalTo()(self.flipsWord.frame.size.width * 2 / 3)
                make.height.equalTo()(self.flipsWord.frame.size.height * 2 / 3)
            } else {
                make.width.equalTo()(self.flipsWord.frame.size.width)
                make.height.equalTo()(self.flipsWord.frame.size.height)
            }
        }
        
        copyright.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.flipsWord.mas_bottom).with().offset()(self.MINIMAL_SPACE_BETWEEN_VIEWS)
            make.left.equalTo()(self.logoContainer)
            make.right.equalTo()(self.logoContainer)
            make.height.equalTo()(self.COPYRIGHT_HEIGHT)
        }
        
        webView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.copyright.mas_bottom).with().offset()(self.MINIMAL_SPACE_BETWEEN_VIEWS)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self)
        }
    }
    
    
    // MARK: - Custom Nav Delegate
    
    func customNavigationBarDidTapLeftButton(navBar: CustomNavigationBar) {
        self.delegate?.aboutViewDidTapBackButton(self)
    }
    
    
    
    
}

protocol AboutViewDelegate: class {
    func aboutViewMakeConstraintToNavigationBarBottom(logoContainer: UIView!)
    func aboutViewDidTapBackButton(aboutView: AboutView!)
}