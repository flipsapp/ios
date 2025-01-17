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

class ChatView: UIView, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, JoinStringsTextFieldDelegate,ChatTableViewCellDelegate {
    
    private let CELL_IDENTIFIER: String = "flipChatCell"
    private let REPLY_VIEW_DEFAULT_HEIGHT : CGFloat = 42.0
    private let REPLY_VIEW_OFFSET : CGFloat = 18.0
    private let REPLY_VIEW_MARGIN : CGFloat = 10.0
    private let NEXT_BUTTON_MARGIN : CGFloat = 8.0
    private let HORIZONTAL_RULER_HEIGHT : CGFloat = 1.0
    private let AUTOPLAY_ON_LOAD_DELAY : Double = 0.3

    private let THUMBNAIL_FADE_DURATION: NSTimeInterval = 0.2
    
    private let ONBOARDING_BUBBLE_TITLE: String = NSLocalizedString("Pretty cool, huh?", comment: "Pretty cool, huh?")
    private let ONBOARDING_BUBBLE_MESSAGE: String = NSLocalizedString("Now it's your turn.", comment: "Now it's your turn.")
    
    private var tableView: UITableView!
    private var darkHorizontalRulerView: UIView!
    private var replyView: UIView!
    private var replyButton: UIButton!
    private var replyTextField: JoinStringsTextField!
    private var nextButton: NextButton!
    
    private var shouldPlayUnreadMessage: Bool = true
    private var keyboardHeight: CGFloat = 0.0
    
    weak var delegate: ChatViewDelegate?
    weak var dataSource : ChatViewDataSource?
    
    private var showOnboarding: Bool = false
    private var bubbleView: BubbleView!

    private var prototypeCell: ChatTableViewCell?
    
    private var indexPathToShow: NSIndexPath?

    private var lastPlayedRow: Int!
    
    private var openingFromPushNotification: Bool!
    
    private var isViewDisappearing: Bool = false
    
    var parentViewController : UIViewController?
    
    var allFlips : [Flip]
    var filteredFlips : [Flip]
    var flipsAppended : [String]
    var manuallyJoinedFlips : [String]
    var flipsManuallyJoinedPlusAppended : [String]
    var flipAppended : Bool
    
    // MARK: - Required initializers
    
    init(showOnboarding: Bool, isOpeningFromPushNotification: Bool) {
        allFlips = [Flip]()
        filteredFlips = [Flip]()
        flipsAppended = [String]()
        manuallyJoinedFlips = [String]()
        flipsManuallyJoinedPlusAppended = [String]()
        flipAppended = false
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.whiteColor()
        
        self.openingFromPushNotification = isOpeningFromPushNotification
        
        self.showOnboarding = showOnboarding
        self.addSubviews()
        self.makeConstraints()
        
        self.updateNextButtonState()

        self.lastPlayedRow = -1
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View Events
    
    func viewWillAppear() {
        self.isViewDisappearing = false
        self.tableView.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatView.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        
        replyView.mas_updateConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.REPLY_VIEW_DEFAULT_HEIGHT + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self)
        })
        self.updateConstraintsIfNeeded()
        
        self.replyTextField.setupMenu()
        
        // ChatView only appears with 0 messages when opened from notification
        if (self.dataSource?.numberOfFlipMessages(self) == 0) {
            self.tableView.alpha = 1
        } else {
            self.tableView.alpha = 0
        }

        self.indexPathToShow = self.indexPathForCellThatShouldBeVisible()
    }
    
    func didLayoutSubviews() {
        self.showNewestMessage(shouldScrollAnimated: false)
    }
    
    func viewWillDisappear() {
        self.indexPathToShow = nil
        self.isViewDisappearing = true
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        
        let visibleCells = tableView.visibleCells
        for cell : ChatTableViewCell in visibleCells as! [ChatTableViewCell] {
            cell.stopMovie()
            cell.releaseResources()
        }
    }
    
    
    // MARK: - Layout View Methods
    
    func addSubviews() {
        tableView = UITableView(frame: self.frame, style: .Plain)
        tableView.registerClass(ChatTableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.separatorStyle = .None
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentOffset = CGPointMake(0, 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        self.addSubview(tableView)
        
        darkHorizontalRulerView = UIView()
        darkHorizontalRulerView.backgroundColor = UIColor.grayColor()
        self.addSubview(darkHorizontalRulerView)
        
        replyView = UIView()
        replyView.backgroundColor = UIColor.whiteColor()
        self.addSubview(replyView)
        
        replyButton = UIButton()
        replyButton.contentMode = .Center
        replyButton.backgroundColor = UIColor.whiteColor()
        replyButton.contentEdgeInsets = UIEdgeInsetsMake(REPLY_VIEW_OFFSET / 2, REPLY_VIEW_OFFSET * 2, REPLY_VIEW_OFFSET / 2, REPLY_VIEW_OFFSET * 2)
        replyButton.addTarget(self, action: #selector(ChatView.didTapReplyButton), forControlEvents: UIControlEvents.TouchUpInside)
        replyButton.setTitle(NSLocalizedString("Reply"), forState: .Normal)
        replyButton.setTitleColor(UIColor.flipOrange(), forState: .Normal)
        replyButton.sizeToFit()
        replyView.addSubview(replyButton)
        
        replyTextField = JoinStringsTextField()
        replyTextField.joinStringsTextFieldDelegate = self
        replyTextField.hidden = true
        replyTextField.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h4)
        replyView.addSubview(replyTextField)
        
        nextButton = NextButton()
        nextButton.contentEdgeInsets = UIEdgeInsetsMake(REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET)
        nextButton.hidden = true
        nextButton.addTarget(self, action: #selector(ChatView.didTapNextButton), forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.sizeToFit()
        replyView.addSubview(nextButton)
        
        if (showOnboarding) {
            bubbleView = BubbleView(title: ONBOARDING_BUBBLE_TITLE, message: ONBOARDING_BUBBLE_MESSAGE, bubbleType: BubbleType.arrowDownFirstLineBold)
            self.addSubview(bubbleView)
        }

    }
    
    func makeConstraints() {
        tableView.mas_makeConstraints( { (make) in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.darkHorizontalRulerView.mas_top)
        })
        
        darkHorizontalRulerView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.HORIZONTAL_RULER_HEIGHT)
            make.bottom.equalTo()(self.replyView.mas_top)
        })
        
        replyView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.REPLY_VIEW_DEFAULT_HEIGHT + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self)
        })
        
        replyButton.mas_makeConstraints( { (make) in
            make.center.equalTo()(self.replyView)
            return ()
        })
        
        replyTextField.mas_makeConstraints( { (make) in
            make.left.equalTo()(self.replyView).with().offset()(self.REPLY_VIEW_OFFSET)
            make.right.equalTo()(self.nextButton.mas_left).with().offset()(-self.REPLY_VIEW_OFFSET)
            make.centerY.equalTo()(self.replyView)
            make.height.equalTo()(self.REPLY_VIEW_DEFAULT_HEIGHT)
        })
        
        nextButton.mas_makeConstraints( { (make) in
            make.right.equalTo()(self.replyView)
            make.bottom.equalTo()(self.NEXT_BUTTON_MARGIN)
            make.width.equalTo()(self.nextButton.frame.width)
        })
        
        if (showOnboarding) {
            bubbleView.mas_makeConstraints({ (make) -> Void in
                make.bottom.equalTo()(self.tableView.mas_bottom)
                make.width.equalTo()(self.bubbleView.getWidth())
                make.height.equalTo()(self.bubbleView.getHeight())
                make.centerX.equalTo()(self)
            })
        }
    }
    
    ////
    // MARK: - Flip Words
    ////
    
    func changeFlipWords(words: [String]) {
        self.replyTextField.setWords(words)
    }
    
    private func indexPathForCellThatShouldBeVisible() -> NSIndexPath? {
        if let numberOfMessages: Int = self.dataSource?.numberOfFlipMessages(self) as Int? {
            if (numberOfMessages > 0) {
                return NSIndexPath(forRow: numberOfMessages - 1, inSection: 0)
            }
        }
        return nil
    }
    
    func showNewestMessage(shouldScrollAnimated scrollAnimated: Bool) {
        
        if (scrollAnimated) {
            self.indexPathToShow = self.indexPathForCellThatShouldBeVisible()
        }

        if (self.indexPathToShow != nil) {
            self.tableView.scrollToRowAtIndexPath(self.indexPathToShow!, atScrollPosition: UITableViewScrollPosition.Top, animated: scrollAnimated)
            if (self.indexPathToShow!.row == 0) {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.tableView.alpha = 1
                }, completion: { (finished) -> Void in
                    let time = 1 * Double(NSEC_PER_SEC)
                    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(time))
                    dispatch_after(delay, dispatch_get_main_queue()) { () -> Void in
                        self.playVideoForVisibleCell()
                    }
                })
            }
        }
        
    }

    
    // MARK: - CustomNavigationBarDelegate
    
    func customNavigationBarDidTapLeftButton(navBar : CustomNavigationBar) {
        delegate?.chatViewDidTapBackButton(self)
    }
    
    
    // MARK: - Data Load Methods
    
    func loadNewFlipMessages() {
        let currentNumberOfCells: Int = self.tableView.numberOfRowsInSection(0)
        
        var newCellsIndexPaths: Array<NSIndexPath> = Array<NSIndexPath>()
        if let newNumberOfCells: Int = self.dataSource?.numberOfFlipMessages(self) {
            for i in (currentNumberOfCells ..< newNumberOfCells) {
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                newCellsIndexPaths.append(indexPath)
            }
        }
        if (newCellsIndexPaths.count > 0) {
            self.tableView.insertRowsAtIndexPaths(newCellsIndexPaths, withRowAnimation: UITableViewRowAnimation.None)
            self.showNewestMessage(shouldScrollAnimated: true)
        }
    }


    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: ChatTableViewCell? = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as! ChatTableViewCell?
        if (cell == nil) {
            cell = ChatTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CELL_IDENTIFIER)
        }
        
        configureCell(cell!, atIndexPath: indexPath)
        return cell!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfMessages: Int? = dataSource?.numberOfFlipMessages(self) as Int?
        if (numberOfMessages == nil) {
            numberOfMessages = 0
        }
        
        return numberOfMessages!
    }
    
    /* There are performance implications to using tableView:heightForRowAtIndexPath: instead of the rowHeight property. Every time a table view is displayed, it calls tableView:heightForRowAtIndexPath: on the delegate for each of its rows, which can result in a significant performance problem with table views having a large number of rows (approximately 1000 or more). */
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (DeviceHelper.sharedInstance.systemVersion() >= 8.0) {
            return UITableViewAutomaticDimension
        }

        let cell = self.getPrototypeCell()

        var size: CGFloat = 0
        if let flipMessage: FlipMessage? = dataSource?.chatView(self, flipMessageAtIndex: indexPath.row) {
            size = cell.heightForFlipMessage(flipMessage!)
        }
        return size
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    // MARK: - Cell Auxiliary Methods
    
    private func getPrototypeCell() -> ChatTableViewCell {
        return (self.tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as! ChatTableViewCell)
    }
    
    private func configureCell(cell: ChatTableViewCell, atIndexPath indexPath: NSIndexPath) {
        if cell.isPlayingFlip() {
            cell.stopMovie()
        }
        
        if let flipMessage: FlipMessage? = dataSource?.chatView(self, flipMessageAtIndex: indexPath.row) {
            cell.setFlipMessage(flipMessage!)
            cell.parentViewController = self.parentViewController
        }
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if ((self.indexPathToShow != nil) && (self.indexPathToShow?.row == indexPath.row)) {
            // Only show the tableview when we are sure that the latest cell will appear.
            if (self.tableView.alpha == 0) {
                let time = 1 * Double(NSEC_PER_SEC)
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(time))
                dispatch_after(delay, dispatch_get_main_queue()) { () -> Void in
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        self.tableView.alpha = 1
                    }, completion: { (finished) -> Void in
                        self.indexPathToShow = nil
                        
                        if (!self.isViewDisappearing) {
                            if (self.replyTextField.text != "") {
                                self.hideReplyButtonAndShowTextField()
                                self.replyTextField.becomeFirstResponder()
                            }
                            
                            if (!self.openingFromPushNotification) {
                                self.playVideoForVisibleCell()
                            }
                        }
                    })
                }
            }
        }
    }
    
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let visibleCells: [AnyObject] = self.tableView.visibleCells
        for cell: ChatTableViewCell in visibleCells as! [ChatTableViewCell] {
            if !self.isCell(cell, totallyVisibleOnView: self) {
                if cell.isPlayingFlip() {
                    cell.stopMovie()
                }
            }
        }
        
        let isKeyboardVisible: Bool = self.replyTextField.isFirstResponder()
        // I'm checking if the superview is not nil to make sure that the view is visible.
        if (isKeyboardVisible && (DeviceHelper.sharedInstance.systemVersion() < 8) && (self.superview != nil)) {
            self.replyTextField.resignFirstResponder()
            replyView.mas_updateConstraints( { (make) in
                make.removeExisting = true
                make.left.equalTo()(self)
                make.right.equalTo()(self)
                make.height.equalTo()(self.REPLY_VIEW_DEFAULT_HEIGHT + self.REPLY_VIEW_MARGIN)
                make.bottom.equalTo()(self)
            })
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
            self.hideTextFieldAndShowReplyButton()
        }
    }
    
    private func isCell(cell: ChatTableViewCell, totallyVisibleOnView view: UIView) -> Bool {
        let videoContainerView: UIView = cell.subviews[0] // Gets video container view from cell
        let convertedVideoContainerViewFrame: CGRect = cell.convertRect(videoContainerView.frame, toView:view)
        if (CGRectContainsRect(view.frame, convertedVideoContainerViewFrame)) {
            return true
        } else {
            return false
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if (!decelerate) {
                self.playVideoForVisibleCell()
            }
        })
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.playVideoForVisibleCell()
        })
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if (self.openingFromPushNotification!) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.playVideoForVisibleCell()
                self.openingFromPushNotification = false
            })
        }
    }

    private func playVideoForVisibleCell() {
        let visibleCells = self.tableView.visibleCells
        for cell : ChatTableViewCell in visibleCells as! [ChatTableViewCell] {
            if (self.isCell(cell, totallyVisibleOnView: self)) {
                let indexPath = self.tableView.indexPathForCell(cell) as NSIndexPath?
                if (indexPath == nil) {
                    return
                }

                let row = indexPath?.row
                if let shouldAutoPlay = dataSource?.chatView(self, shouldAutoPlayFlipMessageAtIndex: row!) {
                    if (shouldAutoPlay && (row != self.lastPlayedRow)) {
                        self.lastPlayedRow = row
                        cell.playMovie()
                    }
                }
            } else {
                cell.stopMovie()
            }
        }
    }

    private func handleReplyTextFieldSize() {
        var textFieldHeight = replyTextField.DEFAULT_HEIGHT
        if (replyTextField.numberOfLines > 1) {
            textFieldHeight = replyTextField.DEFAULT_HEIGHT+replyTextField.DEFAULT_LINE_HEIGHT
        }
        
        replyView.mas_updateConstraints( { (update) in
            update.left.equalTo()(self)
            update.right.equalTo()(self)
            update.height.equalTo()(textFieldHeight + self.REPLY_VIEW_MARGIN)
            update.bottom.equalTo()(self).with().offset()(-self.keyboardHeight)
        })
        
        replyTextField.mas_updateConstraints( { (update) in
            update.left.equalTo()(self.replyView).with().offset()(self.REPLY_VIEW_OFFSET)
            update.right.equalTo()(self.nextButton.mas_left).with().offset()(-self.REPLY_VIEW_OFFSET)
            update.centerY.equalTo()(self.replyView)
            update.height.equalTo()(textFieldHeight)
        })
        self.updateConstraintsIfNeeded()
        
        replyTextField.handleMultipleLines(textFieldHeight)
    }
    
    
    // MARK: - Button Handlers
    
    func didTapReplyButton() {
        hideReplyButtonAndShowTextField()
        
        let visibleCells: [AnyObject] = tableView.visibleCells
        for cell: ChatTableViewCell in visibleCells as! [ChatTableViewCell] {
            cell.stopMovie()
        }
        
        self.replyTextField.becomeFirstResponder()
    }
    
    func didTapNextButton() {
        self.delegate?.chatView(self, didTapNextButtonWithWords: replyTextField.getTextWords())
    }
    
    private func hideReplyButtonAndShowTextField() {
        self.replyButton.hidden = true
        self.replyTextField.hidden = false
        self.nextButton.hidden = false
    }
    
    func hideTextFieldAndShowReplyButton() {
        self.replyButton.hidden = false
        self.replyTextField.hidden = true
        self.nextButton.hidden = true
        self.updateNextButtonState()
    }
    
    func clearReplyTextField() {
        self.replyTextField.text = ""
        self.updateNextButtonState()
    }
    
    
    // MARK: - Keyboard handler
    
    func keyboardDidShow(notification: NSNotification) {
        if (DeviceHelper.sharedInstance.systemVersion() < 8) {
            let info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            keyboardHeight = keyboardFrame.height as CGFloat
        }
        handleReplyTextFieldSize()
    }
    
    func keyboardPanningToFrame(frame: CGRect) {
        self.keyboardHeight = self.frame.height - frame.origin.y
        replyView.mas_updateConstraints( { (make) in
            make.removeExisting = true
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.replyTextField.DEFAULT_HEIGHT + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self).with().offset()(-self.keyboardHeight)
        })
        
        if (self.keyboardHeight == 0) {
            self.hideTextFieldAndShowReplyButton()
        }
    }
    
    
    // MARK: - JoinStringsTextFieldDelegate delegate
    
    func joinStringsTextField(joinStringsTextField: JoinStringsTextField, didChangeText: String!) {
        handleReplyTextFieldSize()
        updateNextButtonState()
    }
    
    func joinStringsTextFieldShouldReturn(joinStringsTextField: JoinStringsTextField) -> Bool {
        if (nextButton.enabled) {
            didTapNextButton()
            return true
        }
        return false
    }
    func getAppendedFlips() -> [String] {
        return flipsAppended
    }
    
    func getManuallyJoinedFlips() -> [String] {
        return manuallyJoinedFlips
    }
    
    func setManuallyJoined(flipText: String){
        manuallyJoinedFlips.append(flipText)
    }
    
    func setManualPlusAppended(flipText: String) {
        flipsManuallyJoinedPlusAppended.append(flipText)
    }
    
    func removeFlipFromArrays(flipText: String){
        if (flipsManuallyJoinedPlusAppended.contains(flipText)){
            
            flipsManuallyJoinedPlusAppended.removeAtIndex(flipsManuallyJoinedPlusAppended.indexOf(flipText)!)
            
            if (flipsAppended.contains(flipText)){
                flipsAppended.removeAtIndex(flipsAppended.indexOf(flipText)!)
            } else {
                manuallyJoinedFlips.removeAtIndex(manuallyJoinedFlips.indexOf(flipText)!)
            }
        }
    }
    
    func flipJustAppended() -> Bool{
        return flipAppended
    }
    
    // MARK: - ChatTableViewCellDelegate
    
    func chatTableViewCellIsVisible(chatTableViewCell: ChatTableViewCell) -> Bool {
        let visibleCells = tableView.visibleCells
        for cell : ChatTableViewCell in visibleCells as! [ChatTableViewCell] {
            if (cell == chatTableViewCell) {
                return true
            }
        }
        
        return false
    }
    
    
    // MARK: - Private methods
    
    private func updateNextButtonState() {
        nextButton.enabled = !replyTextField.text.removeWhiteSpaces().isEmpty
    }
}

@objc protocol ChatViewDelegate {
    
    func chatViewDidTapBackButton(chatView: ChatView)
    
    func chatView(chatView: ChatView, didTapNextButtonWithWords words: [String])
    
    optional func chatViewReloadMessages(chatView: ChatView)
    
    optional func chatView(chatView: ChatView, didDeleteItemAtIndex index: Int)
    
}

protocol ChatViewDataSource: class {
    
    func numberOfFlipMessages(chatView: ChatView) -> Int
    
    func chatView(chatView: ChatView, flipMessageAtIndex index: Int) -> FlipMessage
    
    func chatView(chatView: ChatView, shouldAutoPlayFlipMessageAtIndex index: Int) -> Bool
    
}
