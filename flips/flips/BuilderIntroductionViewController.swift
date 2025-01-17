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

class BuilderIntroductionViewController : UIViewController {
    
    weak var delegate: BuilderIntroductionViewControllerDelegate?
    
    private let CONTENT_MARGIN_LEFT:    CGFloat = 25.0
    private let CONTENT_MARGIN_RIGHT:   CGFloat = -25.0
    private let TOP_CONTAINER_HEIGHT_4S:CGFloat = 60.0
    private let TOP_CONTAINER_HEIGHT:   CGFloat = 120.0
    private let SEPARATOR_HEIGHT:       CGFloat = 50.0
    private let OK_SWEET_BUTTON_HEIGHT: CGFloat = 62.0
    private let OK_SWEET_BUTTON_WIDTH:  CGFloat = 195.0
    private let OK_SWEET_CORNER_RADIUS: CGFloat = 30.0
    private let OK_SWEET_BACKGROUND_COLOR: UIColor = UIColor(RRGGBB: UInt(0x4A90E2))
    
    private var backgroundImage: UIImage!
    private var blurredImageView: UIImageView!
    private var contentTopContainer: UIView!
    private var hiUserLabel: UILabel!
    private var thisIsYourWordBuilderLabel: UILabel!
    private var separatorBetweenNameAndDescription: UIView!
    private var descriptionLabel: UILabel!
    private var separatorBetweenDescriptionAndButton: UIView!
    private var okSweetButton: UIButton!
    private var separatorBetweenButtonAndBottom: UIView!
    
    private let HI_MESSAGE = "Hi"
    private let THIS_IS_YOUR_WORD_MESSAGE = "this is your word builder."
    private let DESCRIPTION_TEXT_MESSAGE = "It's a quick & easy tool to define & add words to use for future messages. We have suggested words to get you started, but feel free to add as many words as you like."
    private let OK_SWEET_MESSAGE = "ok, sweet!"
    
    
    // MARK: - Initialization Methods
    
    convenience init(viewBackground: UIImage!) {
        self.init()
        self.backgroundImage = viewBackground
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addSubviews()
        self.makeConstraints()
    }
    
    func addSubviews() {
        let blurredImage: UIImage = self.applyBlur(self.backgroundImage)
        self.blurredImageView = UIImageView(image: blurredImage)
        self.view.addSubview(blurredImageView)
        
        self.contentTopContainer = UIView()
        self.view.addSubview(contentTopContainer)
        
        self.hiUserLabel = UILabel()
        self.hiUserLabel.numberOfLines = 1
        self.hiUserLabel.font = UIFont.avenirNextUltraLight(UIFont.HeadingSize.h1)
        self.hiUserLabel.text = "\(NSLocalizedString(HI_MESSAGE, comment: HI_MESSAGE)) \(User.loggedUser()!.firstName),"
        self.hiUserLabel.textColor = UIColor.deepSea()
        self.hiUserLabel.textAlignment = NSTextAlignment.Center
        self.hiUserLabel.sizeToFit()
        self.view.addSubview(hiUserLabel)
        
        self.thisIsYourWordBuilderLabel = UILabel()
        self.thisIsYourWordBuilderLabel.numberOfLines = 1
        self.thisIsYourWordBuilderLabel.font = UIFont.avenirNextUltraLight(UIFont.HeadingSize.h2)
        self.thisIsYourWordBuilderLabel.text = NSLocalizedString(THIS_IS_YOUR_WORD_MESSAGE, comment: THIS_IS_YOUR_WORD_MESSAGE)
        self.thisIsYourWordBuilderLabel.textColor = UIColor.deepSea()
        self.thisIsYourWordBuilderLabel.textAlignment = NSTextAlignment.Center
        self.thisIsYourWordBuilderLabel.sizeToFit()
        self.view.addSubview(thisIsYourWordBuilderLabel)
        
        self.separatorBetweenNameAndDescription = UIView()
        self.view.addSubview(separatorBetweenNameAndDescription)
        
        self.descriptionLabel = UILabel()
        self.descriptionLabel.numberOfLines = 0
        
        self.descriptionLabel.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h5)
        self.descriptionLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        self.descriptionLabel.text = NSLocalizedString(DESCRIPTION_TEXT_MESSAGE, comment: DESCRIPTION_TEXT_MESSAGE)
        self.descriptionLabel.textColor = UIColor.deepSea()
        self.descriptionLabel.textAlignment = NSTextAlignment.Center
        self.descriptionLabel.sizeToFit()
        self.view.addSubview(descriptionLabel)
        
        self.separatorBetweenDescriptionAndButton = UIView()
        self.view.addSubview(separatorBetweenDescriptionAndButton)
        
        self.okSweetButton = UIButton()
        self.okSweetButton.addTarget(self, action: #selector(BuilderIntroductionViewController.okSweetButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.okSweetButton.backgroundColor = self.OK_SWEET_BACKGROUND_COLOR
        self.okSweetButton.layer.cornerRadius = self.OK_SWEET_CORNER_RADIUS
        self.okSweetButton.setAttributedTitle(NSAttributedString(string:NSLocalizedString(OK_SWEET_MESSAGE, comment: OK_SWEET_MESSAGE), attributes:[NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.avenirNextRegular(UIFont.HeadingSize.h4)]), forState: UIControlState.Normal)
        self.view.addSubview(okSweetButton)
        
        self.separatorBetweenButtonAndBottom = UIView()
        self.view.addSubview(separatorBetweenButtonAndBottom)
    }
    
    private func makeConstraints() {
        self.blurredImageView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.view)
            make.bottom.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
        }
        
        self.contentTopContainer.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.height.equalTo()(self.TOP_CONTAINER_HEIGHT_4S)
            } else {
                make.height.equalTo()(self.TOP_CONTAINER_HEIGHT)
            }
        }
        
        self.hiUserLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.contentTopContainer.mas_bottom)
            make.left.equalTo()(self.contentTopContainer).with().offset()(self.CONTENT_MARGIN_LEFT)
            make.right.equalTo()(self.contentTopContainer).with().offset()(self.CONTENT_MARGIN_RIGHT)
            make.height.equalTo()(self.hiUserLabel.frame.size.height)
        }
        
        self.thisIsYourWordBuilderLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.hiUserLabel.mas_bottom)
            make.left.equalTo()(self.contentTopContainer).with().offset()(self.CONTENT_MARGIN_LEFT)
            make.right.equalTo()(self.contentTopContainer).with().offset()(self.CONTENT_MARGIN_RIGHT)
            make.height.equalTo()(self.thisIsYourWordBuilderLabel.frame.size.height)
        }
        
        self.separatorBetweenNameAndDescription.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.thisIsYourWordBuilderLabel.mas_bottom)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.equalTo()(self.separatorBetweenDescriptionAndButton)
        }
        
        self.descriptionLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.separatorBetweenNameAndDescription.mas_bottom)
            make.left.equalTo()(self.view).with().offset()(self.CONTENT_MARGIN_LEFT)
            make.right.equalTo()(self.view).with().offset()(self.CONTENT_MARGIN_RIGHT)
        }
        
        self.separatorBetweenDescriptionAndButton.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.descriptionLabel.mas_bottom)
            make.bottom.equalTo()(self.okSweetButton.mas_top)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.greaterThanOrEqualTo()(self.SEPARATOR_HEIGHT)
        }
        
        self.okSweetButton.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self.separatorBetweenButtonAndBottom.mas_top)
            make.centerX.equalTo()(self.view)
            make.height.equalTo()(self.OK_SWEET_BUTTON_HEIGHT)
            make.width.equalTo()(self.OK_SWEET_BUTTON_WIDTH)
        }
        
        self.separatorBetweenButtonAndBottom.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.equalTo()(self.contentTopContainer)
        }
    }
    

    // MARK: - Button Handlers
    
    func okSweetButtonTapped(button: UIButton!) {
        self.delegate?.builderIntroductionViewControllerDidTapOkSweetButton(self)
    }
    

    // MARK: - Image Helper Methods
    
    func applyBlur(image: UIImage) -> UIImage {
        return image.applyBlurWithRadius(30, tintColor: UIColor(white: 200, alpha: 0.7), saturationDeltaFactor: 1.8, maskImage: nil)
    }
}

protocol BuilderIntroductionViewControllerDelegate: class {
    func builderIntroductionViewControllerDidTapOkSweetButton(builderIntroductionViewController: BuilderIntroductionViewController!)
}