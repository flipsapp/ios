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

let RESYNC_INBOX_NOTIFICATION_NAME: String = "resync_inbox_notification"

class InboxViewController : FlipsViewController, InboxViewDelegate, NewFlipViewControllerDelegate, InboxViewDataSource, UserDataSourceDelegate {
    var userDataSource: UserDataSource? {
        didSet {
            if userDataSource != nil {
                userDataSource?.delegate = self
            }
        }
    }
    
    private let DOWNLOAD_MESSAGE_FROM_PUSH_NOTIFICATION_MAX_NUMBER_OF_RETRIES: Int = 20 // aproximately 20 seconds
    private var downloadingMessageFromNotificationRetries: Int = 0
    
    private let animationDuration: NSTimeInterval = 0.25
    
    private var inboxView: InboxView!
    private var syncView: SyncView!
    private var roomIds: NSMutableOrderedSet = NSMutableOrderedSet()
    
    private var roomIdToShow: String?
    private var flipMessageIdToShow: String?
    
    // MARK: - Initialization Methods
    
    init(roomID: String? = nil, flipMessageID: String? = nil) {
        super.init()
        self.roomIdToShow = roomID
        self.flipMessageIdToShow = flipMessageID
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: RESYNC_INBOX_NOTIFICATION_NAME, object: nil)
    }
    
    // MARK: - UIViewController overridden methods

    override func loadView() {
        var showOnboarding = false
        if (!OnboardingHelper.onboardingHasBeenShown()) {
            showOnboarding = true
        }
        
        inboxView = InboxView(showOnboarding: false) // Onboarding is disabled for now.
        inboxView.delegate = self
        inboxView.dataSource = self
        self.view = inboxView
        
        setupSyncView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resyncNotificationReceived:", name: RESYNC_INBOX_NOTIFICATION_NAME, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.inboxView.viewWillAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: DOWNLOAD_FINISHED_NOTIFICATION_NAME, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "messageHistoryReceivedNotificationReceived:", name: PUBNUB_DID_FETCH_MESSAGE_HISTORY, object: nil)

        syncView.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DOWNLOAD_FINISHED_NOTIFICATION_NAME, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: PUBNUB_DID_FETCH_MESSAGE_HISTORY, object: nil)
        
        self.roomIdToShow = nil
        self.flipMessageIdToShow = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let userDataSource = self.userDataSource {
            if (userDataSource.isDownloadingFlips == true) {
                syncView.image = imageForView()
                syncView.setDownloadCount(1, ofTotal: userDataSource.flipsDownloadCount.value)
                syncView.alpha = 0
                syncView.hidden = false
                
                UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                    self.syncView.alpha = 1
                })
            }
        }
        self.refreshRooms()
        
        if (self.flipMessageIdToShow != nil) {
            self.showActivityIndicator(userInteractionEnabled: true, message: NSLocalizedString("Downloading message"))
            self.openRoomForPushNotificationIfMessageReceived()
        }
    }
    
    private func openRoomForPushNotificationIfMessageReceived() {
        if let roomID = self.roomIdToShow {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                var flipMessageAlreadyReceived = false
                if let flipMessageID: String = self.flipMessageIdToShow {
                    let flipMessageDataSource: FlipMessageDataSource = FlipMessageDataSource()
                    if let flipMessage: FlipMessage = flipMessageDataSource.getFlipMessageById(flipMessageID) {
                        flipMessageAlreadyReceived = true
                    }
                }
                
                if (flipMessageAlreadyReceived) {
                    self.openThreadViewControllerWithRoomID(roomID)
                    self.hideActivityIndicator()
                    self.roomIdToShow = nil
                    self.flipMessageIdToShow = nil
                } else {
                    self.retryToOpenRoomForPushNotification()
                }
            })
        }
    }
    
    private func retryToOpenRoomForPushNotification() {
        let time = 1 * Double(NSEC_PER_SEC)
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(time))
        dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            self.downloadingMessageFromNotificationRetries++
            if (self.downloadingMessageFromNotificationRetries < self.DOWNLOAD_MESSAGE_FROM_PUSH_NOTIFICATION_MAX_NUMBER_OF_RETRIES) {
                self.openRoomForPushNotificationIfMessageReceived()
            } else {
                self.hideActivityIndicator()
                self.roomIdToShow = nil
                self.flipMessageIdToShow = nil
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var alertView = UIAlertView(title: nil, message: NSLocalizedString("Download failed. Please try again later."), delegate: nil, cancelButtonTitle: "OK")
                    alertView.show()
                    
                })
            }
        })
    }
    
    func imageForView() -> UIImage {
        UIGraphicsBeginImageContext(view.bounds.size)
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setupSyncView() {
        if let views = NSBundle.mainBundle().loadNibNamed("SyncView", owner: self, options: nil) {
            if let syncView = views[0] as? SyncView {
                syncView.hidden = true
                
                self.syncView = syncView
                
                view.addSubview(syncView)
                
                syncView.mas_makeConstraints { (make) -> Void in
                    make.top.equalTo()(self.view)
                    make.trailing.equalTo()(self.view)
                    make.leading.equalTo()(self.view)
                }
            }
        }
    }
    
    // MARK: - InboxViewDelegate
    
    func inboxViewDidTapComposeButton(inboxView : InboxView) {
        var newFlipViewNavigationController = NewFlipViewController.instantiateNavigationController()
        var viewController = newFlipViewNavigationController.topViewController as NewFlipViewController
        viewController.delegate = self
        self.navigationController?.presentViewController(newFlipViewNavigationController, animated: true, completion: nil)
    }
    
    func inboxViewDidTapSettingsButton(inboxView : InboxView) {
        var settingsViewController = SettingsViewController()
        var navigationController = UINavigationController(rootViewController: settingsViewController)
        
        settingsViewController.modalPresentationStyle = UIModalPresentationStyle.FullScreen;
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func inboxViewDidTapBuilderButton(inboxView : InboxView) {
        var builderViewController = BuilderViewController()
        self.navigationController?.pushViewController(builderViewController, animated:true)
    }
    
    func inboxView(inboxView : InboxView, didTapAtItemAtIndex index: Int) {
        var roomID: String!
        roomID = self.roomIds.objectAtIndex(index) as String
        self.openThreadViewControllerWithRoomID(roomID)
    }
    
    
    // MARK: - Room Handlers
    
    private func refreshRooms() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            let roomDataSource = RoomDataSource()
            let rooms = roomDataSource.getMyRoomsOrderedByMostRecentMessage()
            self.roomIds.removeAllObjects()
            for room in rooms {
                self.roomIds.addObject(room.roomID)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.inboxView.reloadData()
            })
        })
    }
    
    private func openThreadViewControllerWithRoomID(roomID: String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let roomDataSource = RoomDataSource()
            let room = roomDataSource.retrieveRoomWithId(roomID)
            
            let chatViewController: ChatViewController = ChatViewController(room: room)
            self.navigationController?.pushViewController(chatViewController, animated: true)
        })
    }
    
    
    // MARK: - Messages Notification Handler

    func messageHistoryReceivedNotificationReceived(notification: NSNotification) {
        self.refreshRooms()
    }

    func notificationReceived(notification: NSNotification) {
        var userInfo: Dictionary = notification.userInfo!
        var flipID: String = userInfo[DOWNLOAD_FINISHED_NOTIFICATION_PARAM_FLIP_KEY] as String
        var receivedFlipMessageID: String = userInfo[DOWNLOAD_FINISHED_NOTIFICATION_PARAM_MESSAGE_KEY] as String
        let flipDataSource: FlipDataSource = FlipDataSource()
        if let flip = flipDataSource.retrieveFlipWithId(flipID) {
            if (userInfo[DOWNLOAD_FINISHED_NOTIFICATION_PARAM_FAIL_KEY] != nil) {
                println("Thumbnail download failed for flip: \(flip.flipID)")
            } else {
                self.refreshRooms()
            }
        } else {
            UIAlertView.showUnableToLoadFlip()
        }
        
        if let roomID: String = self.roomIdToShow {
            if let flipMessageID: String = self.flipMessageIdToShow {
                if (flipMessageID == receivedFlipMessageID) {
                    self.hideActivityIndicator()
                    self.roomIdToShow = nil
                    self.flipMessageIdToShow = nil
                    self.openThreadViewControllerWithRoomID(roomID)
                }
            }
        }
    }
    
    func resyncNotificationReceived(notification: NSNotification) {
        PersistentManager.sharedInstance.syncUserData({ (success, flipError, userDataSource) -> Void in
            self.userDataSource = userDataSource
        })
    }
    
    
    // MARK: - NewFlipViewControllerDelegate
    
    func newFlipViewController(viewController: NewFlipViewController, didSendMessageToRoom roomID: String) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            let roomDataSource = RoomDataSource()
            let room = roomDataSource.retrieveRoomWithId(roomID)
            self.navigationController?.pushViewController(ChatViewController(room: room), animated: true)
        })
    }
    
    
    // MARK: - InboxViewDataSource

    func numberOfRooms() -> Int {
        return self.roomIds.count
    }
    
    func inboxView(inboxView: InboxView, roomAtIndex index: Int) -> String {
        return self.roomIds.objectAtIndex(index) as String
    }
    
    func inboxView(inboxView: InboxView, didRemoveRoomAtIndex index: Int) {
        self.roomIds.removeObjectAtIndex(index)
    }
    
    
    // MARK: - UserDataSourceDelegate
    
    func userDataSource(userDataSource: UserDataSource, didDownloadFlip: Flip) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // update sync counter
            self.syncView.setDownloadCount(userDataSource.flipsDownloadCounter.value, ofTotal: userDataSource.flipsDownloadCount.value)
        })
    }
    
    func userDataSourceDidFinishFlipsDownload(userDataSource: UserDataSource) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // dismiss sync view
            UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                self.syncView.alpha = 0
            }, completion: { (done) -> Void in
                self.syncView.hidden = true
                self.syncView.alpha = 1
            })
        })
    }
}