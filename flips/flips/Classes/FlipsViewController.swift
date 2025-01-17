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

class FlipsViewController : UIViewController {
    
    private let ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION = 0.25
    private let ACTIVITY_INDICATOR_SIZE: CGFloat = 100
    
    private let LOADING_CONTAINER_VERTICAL_MARGIN: CGFloat = 10
    private let LOADING_CONTAINER_HORIZONTAL_MARGIN: CGFloat = 20
    private let LOADING_MESSAGE_TOP_MARGIN: CGFloat = 15

    private var overlayView: UIImageView!
    private var loadingContainer: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private var loadingMessageLabel: UILabel!
    
    var draftingTable : DraftingTable?
    
    // MARK: - Init methods
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.draftingTable = DraftingTable.sharedInstance
    }
    
    required init?(coder: NSCoder) {
		super.init(coder: coder)
        self.draftingTable = DraftingTable.sharedInstance
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nil, bundle: nil)
        self.draftingTable = DraftingTable.sharedInstance
    }
    
    
    // MARK: - Overridden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        self.setupActivityIndicator()
        self.view.bringSubviewToFront(self.activityIndicator)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Default is light - to apply black content you should override this method
        return UIStatusBarStyle.LightContent
    }
    
    
    // MARK: Activity Indicator Methods
    
    internal func setupActivityIndicator() {
        loadingContainer = UIView()
        loadingContainer.clipsToBounds = true
        loadingContainer.layer.cornerRadius = 8
        loadingContainer.layer.masksToBounds = true
        loadingContainer.backgroundColor = UIColor.blackColor()
        loadingContainer.alpha = 0
        self.view.addSubview(loadingContainer)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        loadingContainer.addSubview(activityIndicator)
        
        loadingMessageLabel = UILabel()
        loadingMessageLabel.font = UIFont.avenirNextUltraLight(UIFont.HeadingSize.h4)
        loadingMessageLabel.textColor = UIColor.whiteColor()
        loadingMessageLabel.textAlignment = NSTextAlignment.Center
        loadingMessageLabel.numberOfLines = 2
        loadingContainer.addSubview(loadingMessageLabel)
    }
    
    func showActivityIndicator(userInteractionEnabled: Bool = false, message: String? = nil) {
        
        if !NSThread.isMainThread() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.performShowActivityIndicator(userInteractionEnabled, message: message)
            })
        }
        else {
            self.performShowActivityIndicator(userInteractionEnabled, message: message)
        }

        
    }
    
    private func performShowActivityIndicator(userInteractionEnabled: Bool = false, message: String? = nil) {
        
        self.view.bringSubviewToFront(self.loadingContainer)
        
        let isShowingMessage: Bool = (message != nil)
        if (isShowingMessage) {
            self.loadingMessageLabel.text = message!
        } else {
            self.loadingMessageLabel.text = ""
        }
        self.updateLoadingViewConstraints(isShowingMessage)
        
        self.view.userInteractionEnabled = userInteractionEnabled
        self.activityIndicator.startAnimating()
        UIView.animateWithDuration(self.ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION, animations: { () -> Void in
            self.loadingContainer.alpha = 0.8
        })
        
    }
    
    private func updateLoadingViewConstraints(isShowingText: Bool) {
        loadingMessageLabel.sizeToFit()
        
        var containerHeight = self.ACTIVITY_INDICATOR_SIZE
        var containerWidth = self.ACTIVITY_INDICATOR_SIZE
        if (isShowingText) {
            containerHeight = self.ACTIVITY_INDICATOR_SIZE + loadingMessageLabel.frame.size.height + LOADING_CONTAINER_VERTICAL_MARGIN
            containerWidth = loadingMessageLabel.frame.size.width + LOADING_CONTAINER_HORIZONTAL_MARGIN
        }
        
        loadingContainer.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.center.equalTo()(self.view)
            update.width.equalTo()(containerWidth)
            update.height.equalTo()(containerHeight)
        }
        
        activityIndicator.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.top.equalTo()(self.loadingContainer)
            update.centerX.equalTo()(self.loadingContainer)
            update.width.equalTo()(self.ACTIVITY_INDICATOR_SIZE)
            update.height.equalTo()(self.ACTIVITY_INDICATOR_SIZE)
        }
        
        loadingMessageLabel.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.centerX.equalTo()(self.loadingContainer)
            update.top.equalTo()(self.loadingContainer.mas_centerY).offset()(self.LOADING_MESSAGE_TOP_MARGIN)
            update.width.equalTo()(self.loadingMessageLabel.frame.size.width)
            update.height.equalTo()(self.loadingMessageLabel.frame.size.height)
        }
        
        self.view.updateConstraints()
    }
    
    func hideActivityIndicator() {
        
        if !NSThread.isMainThread() {
        
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.performHideActivityIndicator()
            })
            
        }
        else {
            self.performHideActivityIndicator()
        }
        
    }
    
    private func performHideActivityIndicator() {
        
        self.view.userInteractionEnabled = true
        
        UIView.animateWithDuration(self.ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION, animations: { () -> Void in
            self.loadingContainer?.alpha = 0
            }, completion: { (finished) -> Void in
                self.activityIndicator?.stopAnimating()
        })
        
    }
    
    func previousViewController() -> UIViewController? {
        let numberOfViewControllers = self.navigationController?.viewControllers.count
        if (numberOfViewControllers < 2) {
            return nil
        }
        
        return self.navigationController?.viewControllers[numberOfViewControllers! - 2] as UIViewController!
    }
    
    ////
    // MARK: - Onboarding Overlay Methods
    ////
    
    func shouldShowOnboarding(onboardingKey : String) -> (Bool) {
        return !NSUserDefaults.standardUserDefaults().boolForKey(onboardingKey);
    }
    
    func setupOnboardingInWindow(onboardingKey : String, onboardingImage : UIImage) {
        
        if (shouldShowOnboarding(onboardingKey)) {
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(FlipsViewController.onOnboardingOverlayClick))
            singleTap.numberOfTapsRequired = 1
            
            overlayView = UIImageView(image: onboardingImage)
            overlayView.userInteractionEnabled = true
            overlayView.addGestureRecognizer(singleTap)
            
            let window = UIApplication.sharedApplication().keyWindow
            window!.addSubview(overlayView)
            
            overlayView.mas_makeConstraints { (make) -> Void in
                make.top.equalTo()(window)
                make.left.equalTo()(window)
                make.right.equalTo()(window)
                make.bottom.equalTo()(window)
            }
            
            let userDefaults = NSUserDefaults.standardUserDefaults();
            userDefaults.setBool(true, forKey: onboardingKey);
            userDefaults.synchronize();
            
        }
        
    }
    
    func setupOnboardingInNavigationController(onboardingKey : String, onboardingImage : UIImage) {
        
        if (shouldShowOnboarding(onboardingKey)) {
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(FlipsViewController.onOnboardingOverlayClick))
            singleTap.numberOfTapsRequired = 1
            
            overlayView = UIImageView(image: onboardingImage)
            overlayView.userInteractionEnabled = true
            overlayView.addGestureRecognizer(singleTap)
            
            self.navigationController?.view.addSubview(overlayView)
            
            overlayView.mas_makeConstraints { (make) -> Void in
                make.top.equalTo()(self.navigationController?.view)
                make.left.equalTo()(self.navigationController?.view)
                make.right.equalTo()(self.navigationController?.view)
                make.bottom.equalTo()(self.navigationController?.view)
            }
            
            let userDefaults = NSUserDefaults.standardUserDefaults();
            userDefaults.setBool(true, forKey: onboardingKey);
            userDefaults.synchronize();
            
        }
        
    }
    
    func onOnboardingOverlayClick() {
        overlayView.removeFromSuperview()
    }
    
}
