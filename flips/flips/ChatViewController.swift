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

class ChatViewController: FlipsViewController, ChatViewDelegate, ChatViewDataSource, ComposeViewControllerDelegate {
    
    private let groupTitle: String = NSLocalizedString("Group Chat")
    
    private var chatView: ChatView!
    private var groupParticipantsView: GroupParticipantsView?
    
    private var chatTitle: String!
    
    private var roomID: String!
    private var flipMessages = NSMutableOrderedSet()
    
    private var flipMessageIdFromPushNotification: String?
    
    // MARK: - Initializers
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(room: Room, andFlipMessageIdFromPushNotification flipMessageID: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.chatTitle = room.roomName()
        self.roomID = room.roomID
        self.flipMessageIdFromPushNotification = flipMessageID

        if (room.participants.count > 2) {
            self.chatTitle = groupTitle
            self.groupParticipantsView = GroupParticipantsView(participants: room.participants.allObjects as Array<User> as [User])
        }
        
        let roomMessages: [FlipMessage] = room.flipMessages.array as [FlipMessage]
        for flipMessage in roomMessages {
            if (!flipMessage.removed.boolValue) {
                self.flipMessages.addObject(flipMessage)
            }
        }
    }
    
    
    // MARK - Overridden Methods
    
    override func loadView() {
        var showOnboarding = false
        if (!OnboardingHelper.onboardingHasBeenShown()) {
            showOnboarding = true
        }
        
        let isOpeningFromNotification = (self.flipMessageIdFromPushNotification != nil)
        
        self.chatView = ChatView(showOnboarding: false, isOpeningFromPushNotification: isOpeningFromNotification) // Onboarding is disabled for now.
        self.chatView.delegate = self
        self.view = self.chatView
        
        self.setupWhiteNavBarWithBackButton(self.chatTitle)

        if (self.groupParticipantsView != nil) {
            var participantsButton = UIBarButtonItem(image: UIImage(named: "Group_Participants_Icon") , style: .Done, target: self, action: "groupParticipantsButtonTapped")
            self.navigationItem.rightBarButtonItem = participantsButton

            let participantsViewInitialY: CGFloat = -self.groupParticipantsView!.calculatedHeight()
            
            self.view.addSubview(self.groupParticipantsView!)
            self.groupParticipantsView!.mas_makeConstraints( { (make: MASConstraintMaker!) -> Void in
                make.top.equalTo()(self.view).with().offset()(participantsViewInitialY)
                make.leading.equalTo()(self.view)
                make.trailing.equalTo()(self.view)
                make.height.equalTo()(self.groupParticipantsView!.calculatedHeight())
            })
            self.groupParticipantsView!.setupView()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if (DeviceHelper.sharedInstance.systemVersion() >= 8) {
            // It doesn't work properly on iOS7
            self.view.addKeyboardPanningWithFrameBasedActionHandler(nil, constraintBasedActionHandler: { (keyBoardFrameInView: CGRect, openning: Bool, closing: Bool) -> Void in
                self.chatView.keyboardPanningToFrame(keyBoardFrameInView)
            })
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: DOWNLOAD_FINISHED_NOTIFICATION_NAME, object: nil)
        
        self.chatView.delegate = self
        self.chatView.dataSource = self
        self.chatView.viewWillAppear()
        
        if let flipMessageID = self.flipMessageIdFromPushNotification {
            let flipMessagesArray: [FlipMessage] = self.flipMessages.array as [FlipMessage]
            var alreadyReceivedMessage: Bool = false
            for flipMessage in flipMessagesArray {
                if (flipMessage.flipMessageID == flipMessageID) {
                    alreadyReceivedMessage = true
                }
            }
            
            if (!alreadyReceivedMessage) {
                self.showActivityIndicator(userInteractionEnabled: true, message: NSLocalizedString("Downloading message"))
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.groupParticipantsView?.mas_updateConstraints( { (update: MASConstraintMaker!) -> Void in
            update.removeExisting = true
            update.top.equalTo()(self.view).with().offset()(CGRectGetMaxY(self.navigationController!.navigationBar.frame))
            update.leading.equalTo()(self.view)
            update.trailing.equalTo()(self.view)
            update.height.equalTo()(0)
        })
        self.groupParticipantsView?.updateConstraintsIfNeeded()
        self.groupParticipantsView?.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.chatView.didLayoutSubviews()
        
        if (DeviceHelper.sharedInstance.systemVersion() < 8) {
            // Required only for iOS7
            self.chatView.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DOWNLOAD_FINISHED_NOTIFICATION_NAME, object: nil)
        
        self.chatView.viewWillDisappear()
        self.chatView.dataSource = nil
        self.chatView.delegate = nil
        
        if (DeviceHelper.sharedInstance.systemVersion() >= 8) {
            self.chatView.removeKeyboardControl()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.BlackOpaque
    }
    
    
    // MARK: - FlipMessages Load Methods
    
    func reloadFlipMessages() {
        let flipMessageDataSource: FlipMessageDataSource = FlipMessageDataSource()
        let flipMessages = flipMessageDataSource.flipMessagesForRoomID(self.roomID)
        for flipMessage in flipMessages {
            self.flipMessages.addObject(flipMessage)
        }
    }
    
    // MARK: - jump to newest message
    
    func showChatViewNewestMessage(shouldScrollAnimated: Bool) {
        if (self.chatView != nil) {
            self.chatView.showNewestMessage(shouldScrollAnimated: shouldScrollAnimated)
        }
    }
    
    // MARK: - Delegate methods
    
    func chatViewDidTapBackButton(chatView: ChatView) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func chatView(chatView: ChatView, didTapNextButtonWithWords words : [String]) {
        var composeViewController = ComposeViewController(roomID: self.roomID, composeTitle: self.chatTitle, words: words)
        composeViewController.delegate = self
        self.navigationController?.pushViewController(composeViewController, animated: true)
    }
    
    func groupParticipantsButtonTapped() {
        if (self.groupParticipantsView?.frame.height == 0) {
            // show
            self.groupParticipantsView?.mas_updateConstraints({ (update: MASConstraintMaker!) -> Void in
                update.removeExisting = true
                update.top.equalTo()(self.view).with().offset()(CGRectGetMaxY(self.navigationController!.navigationBar.frame))
                update.leading.equalTo()(self.view)
                update.trailing.equalTo()(self.view)
                update.height.equalTo()(self.groupParticipantsView?.calculatedHeight())
            })
        } else {
            // dismiss
            self.groupParticipantsView?.mas_updateConstraints({ (update: MASConstraintMaker!) -> Void in
                update.removeExisting = true
                update.top.equalTo()(self.view).with().offset()(CGRectGetMaxY(self.navigationController!.navigationBar.frame))
                update.leading.equalTo()(self.view)
                update.trailing.equalTo()(self.view)
                update.height.equalTo()(0)
            })
        }

        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - ChatViewDataSource
    
    func numberOfFlipMessages(chatView: ChatView) -> Int {
        var numberOfFlipMessages: Int!
        numberOfFlipMessages = self.flipMessages.count
        return numberOfFlipMessages
    }
    
    func chatView(chatView: ChatView, flipMessageAtIndex index: Int) -> FlipMessage {
        return self.flipMessages.objectAtIndex(index) as FlipMessage
    }
    
    func chatView(chatView: ChatView, shouldAutoPlayFlipMessageAtIndex index: Int) -> Bool {
//        let flipMessage = flipMessageDataSource.retrieveFlipMessageById(flipMessageIds[index])
//        return flipMessage.notRead.boolValue
        return true
    }
    
    
    // MARK: - Messages Notification Handler
    
    func notificationReceived(notification: NSNotification) {
        self.reloadFlipMessages()
        
        var scrollToReceivedMessage: Bool = false
        if (self.flipMessageIdFromPushNotification != nil) {
            if let flipMessageIdReceived: String = notification.userInfo?[DOWNLOAD_FINISHED_NOTIFICATION_PARAM_MESSAGE_KEY] as? String {
                if (flipMessageIdReceived == self.flipMessageIdFromPushNotification) {
                    scrollToReceivedMessage = true
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.chatView.loadNewFlipMessages()
            self.showChatViewNewestMessage(scrollToReceivedMessage)
            if (scrollToReceivedMessage) {
                self.hideActivityIndicator()
            }
        })
    }
    
    
    // MARK: - ComposeViewControllerDelegate
    
    func composeViewController(viewController: ComposeViewController, didSendMessageToRoom roomID: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            self.reloadFlipMessages()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationController?.popToViewController(self, animated: true)
                self.chatView.clearReplyTextField()
                self.chatView.hideTextFieldAndShowReplyButton()
                self.chatView.loadNewFlipMessages()
                self.chatView.showNewestMessage(shouldScrollAnimated: false)
            })
        })
    }
    
    func composeViewController(viewController: ComposeViewController, didChangeFlipWords words: [String]) {
        self.chatView.changeFlipWords(words)
    }
}