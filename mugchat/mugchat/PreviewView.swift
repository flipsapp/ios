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
import MediaPlayer

public class PreviewView: UIView, CustomNavigationBarDelegate, UIGestureRecognizerDelegate {
    
    private let LOW_RES_VIDEO_WIDTH: CGFloat = 240.0
    private let LOW_RES_VIDEO_MARGIN: CGFloat = 15.0
    private let LOW_RES_LABEL_MARGIN: CGFloat = 15.0
    private let HI_RES_LABEL_MARGIN: CGFloat = 40.0

    var delegate: PreviewViewDelegate?
    
    private var flipContainerView: UIView!
    private var moviePlayer: MPMoviePlayerController!
    private var flipVideoURL: NSURL!
    
    private var sendContainerView: UIView!
    private var sendContainerButtonView: UIView!
    private var sendLabel: UILabel!
    private var sendImage: UIImage!
    private var sendImageButton: UIButton!
    
    private var isPlaying = false
    
    override init() {
        super.init()
        
        self.addSubviews()
    }
    
    func viewDidLoad() {
        makeConstraints()
    }
    
    func viewDidAppear() {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self)
    }
    
    func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
        self.stopMovie()
    }
    
    func showVideoCreationError() {
        ActivityIndicatorHelper.hideActivityIndicatorAtView(self)
        
        var alertView = UIAlertView(title: "",
            message: NSLocalizedString("Preview couldn't be created. Please try again later.", comment: "Preview couldn't be created. Please try again later."),
            delegate: nil,
            cancelButtonTitle: NSLocalizedString("OK", comment: "OK"))
        alertView.show()
    }
    
    func setVideoURL(videoURL: NSURL) {
        ActivityIndicatorHelper.hideActivityIndicatorAtView(self)
        
        self.flipVideoURL = videoURL
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.moviePlayer.contentURL = self.flipVideoURL
            self.moviePlayer.prepareToPlay()
        })
        
//        self.addSubviews()
//        self.makeConstraints()
        
        let oneSecond = 1 * Double(NSEC_PER_SEC)
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(oneSecond))
        dispatch_after(delay, dispatch_get_main_queue()) { () -> Void in
//            self.addMoviePlayer()
//            self.playOrPausePreview()
        }
    }
    
    func addSubviews() {
        flipContainerView = UIView()
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "playOrPausePreview")
        tapGestureRecognizer.delegate = self
        flipContainerView.addGestureRecognizer(tapGestureRecognizer)
        flipContainerView.backgroundColor = UIColor.deepSea()
        self.addSubview(flipContainerView)
        
        self.addMoviePlayer()
        
        self.sendContainerView = UIView()
        self.sendContainerView.backgroundColor = UIColor.avacado()
        self.addSubview(sendContainerView)
        
        
        self.sendLabel = UILabel()
        self.sendLabel.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h1)
        self.sendLabel.text = "Send"
        self.sendLabel.textColor = UIColor.whiteColor()
        self.sendContainerView.addSubview(sendLabel)
        
        self.sendImage = UIImage(named: "Send")
        self.sendImageButton = UIButton()
        self.sendImageButton.addTarget(self, action: "sendButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        self.sendImageButton.setImage(self.sendImage, forState: UIControlState.Normal)
        
        self.sendContainerView.addSubview(sendImageButton)
    }
    
    func addMoviePlayer() {
        self.moviePlayer = MPMoviePlayerController(contentURL: self.flipVideoURL)
        self.moviePlayer.controlStyle = MPMovieControlStyle.None
        self.moviePlayer.scalingMode = MPMovieScalingMode.AspectFill
        self.moviePlayer.shouldAutoplay = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "moviePlayerDidFinish:", name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
        flipContainerView.addSubview(self.moviePlayer.view)
        
        self.layoutIfNeeded()
    }
    
    func makeConstraints() {
        self.flipContainerView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)

            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.height.equalTo()(self.LOW_RES_VIDEO_WIDTH + (2 * self.LOW_RES_VIDEO_MARGIN))
            } else {
                make.height.equalTo()(self.mas_width)
            }

        }

        // asking help to delegate to align the container with navigation bar
        self.delegate?.previewViewMakeConstraintToNavigationBarBottom(self.flipContainerView)
        
        self.moviePlayer.view.mas_makeConstraints({ (make) -> Void in
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.centerX.equalTo()(self.flipContainerView)
                make.centerY.equalTo()(self.flipContainerView)
                make.width.equalTo()(self.LOW_RES_VIDEO_WIDTH)
            } else {
                make.top.equalTo()(self.flipContainerView)
                make.left.equalTo()(self.flipContainerView)
                make.right.equalTo()(self.flipContainerView)
            }
            
            make.height.equalTo()(self.moviePlayer.view.mas_width)
        })
        
        self.sendContainerView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.flipContainerView.mas_bottom)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self)
        }
        
        self.sendLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.sendContainerView)
            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.top.equalTo()(self.LOW_RES_LABEL_MARGIN);
            } else {
                make.top.equalTo()(self.HI_RES_LABEL_MARGIN);
            }
        }

        self.sendImageButton.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.sendContainerView)

            if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
                make.top.equalTo()(self.sendLabel.mas_bottom).with().offset()(self.LOW_RES_LABEL_MARGIN);
            } else {
                make.top.equalTo()(self.sendLabel.mas_bottom).with().offset()(self.HI_RES_LABEL_MARGIN);
            }
        }
    }
    
    func sendButtonTapped(sendButton: UIButton!) {
        self.delegate?.previewButtonDidTapSendButton(self)
    }
    
    
    // MARK: - MPMoviePlayerPlaybackDidFinishNotification
    
    func moviePlayerDidFinish(notification: NSNotification) {
        self.isPlaying = false
        let player = notification.object as MPMoviePlayerController
        let delayBetweenExecutions = 1.0 * Double(NSEC_PER_SEC)
        let oneSecond = dispatch_time(DISPATCH_TIME_NOW, Int64(delayBetweenExecutions))
        dispatch_after(oneSecond, dispatch_get_main_queue()) { () -> Void in
            self.playMovie()
        }
    }
    
    
    // MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    // MARK: - Movie player controls
    
    func playMovie() {
        self.isPlaying = true
        self.moviePlayer.play()
    }
    
    func pauseMovie() {
        self.isPlaying = false
        self.moviePlayer.pause()
    }
    
    func stopMovie() {
        self.isPlaying = false
        self.moviePlayer.stop()
    }
    
    func playOrPausePreview() {
        if (self.isPlaying) {
            self.pauseMovie()
        } else {
            self.playMovie()
        }
    }
    
    
    // MARK: - Nav Bar Delegate
    
    func customNavigationBarDidTapLeftButton(navBar: CustomNavigationBar) {
        self.delegate?.previewViewDidTapBackButton(self)
    }
    
    
    // MARK: - Required inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol PreviewViewDelegate {
    func previewViewDidTapBackButton(previewView: PreviewView!)
    func previewButtonDidTapSendButton(previewView: PreviewView!)
    func previewViewMakeConstraintToNavigationBarBottom(container: UIView!)
}