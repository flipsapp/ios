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


extension UIViewController {
    
    // MARK: - Public Methods
    
    func setupWhiteNavBarWithCloseButton(title: String) {
        setupWhiteNavBarWithoutButtons(title)
        
        let closeBarButton = UIBarButtonItem(image: UIImage(named: "Cancel") , style: .Done, target: self, action: #selector(UIViewController.closeButtonTapped))
        self.navigationItem.leftBarButtonItem = closeBarButton
    }
    
    func setupWhiteNavBarWithBackButton(title: String) {
        setupWhiteNavBarWithoutButtons(title)
        
        let backBarButton = UIBarButtonItem(image: UIImage(named: "Back_Orange") , style: .Done, target: self, action: #selector(UIViewController.backButtonTapped))
        self.navigationItem.leftBarButtonItem = backBarButton
    }
    
    func setupWhiteNavBarWithoutBackButtonWithRightDoneButton(title: String) {
        setupWhiteNavBarWithoutButtons(title)
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(UIViewController.doneButtonTapped))
        doneButton.tintColor = UIColor.flipOrange()
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
	func setupWhiteNavBarWithCancelButton(title: String) {
		setupWhiteNavBarWithoutButtons(title)
		
		let backBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(UIViewController.closeButtonTapped))
		self.navigationItem.leftBarButtonItem = backBarButton
	}
	
    func setupWhiteNavBarWithoutButtons(title: String) {
        self.setNavBarColor()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.avenirNextDemiBold(UIFont.HeadingSize.h2)
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.textAlignment = .Center
        titleLabel.sizeToFit()
        self.navigationItem.titleView = titleLabel
   
        self.navigationItem.hidesBackButton = true
    }
    
    func setupOrangeNavBarWithBackButton(title: String) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.avenirNextDemiBold(UIFont.HeadingSize.h2)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = .Center
        titleLabel.sizeToFit()
        self.navigationItem.titleView = titleLabel
        
        let backBarButton = UIBarButtonItem(image: UIImage(named: "Back_White") , style: .Done, target: self, action: #selector(UIViewController.backButtonTapped))
        backBarButton.tintColor = UIColor.whiteColor()
        self.navigationItem.leftBarButtonItem = backBarButton
    }

    // MARK: - Nav Button Actions
    
    func closeButtonTapped() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func doneButtonTapped() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func backButtonTapped() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - Private Methods
    
    private func setNavBarColor() {
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.alpha = 0.9
        self.navigationController?.navigationBar.tintColor = .flipOrange()
    }
}