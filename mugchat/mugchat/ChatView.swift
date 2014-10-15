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

class ChatView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var mugs = [
        MugVideo(message: "Welcome to MugChat", videoPath: "welcome_mugchat", timestamp: "8:23 am", avatarPath: "tmp_homer", thumbnailPath: "movie_thumbnail.png", received: false),
        MugVideo(message: "Bollywood!!!", videoPath: "bollywood", timestamp: "8:24 am", avatarPath: "tmp_homer", thumbnailPath: "bollywood_thumbnail.jpeg", received: false),
        MugVideo(message: "Wanna coffee?", videoPath: "wanna_coffee", timestamp: "8:25 am", avatarPath: "tmp_homer", thumbnailPath: "coffee_thumbnail.jpeg", received: false)
    ]
    
    var oldestUnreadMessageIndex = 1
    
    private let CELL_IDENTIFIER = "mugChatCell"
    private let REPLY_BUTTON_TOP_MARGIN : CGFloat = 18.0
    private let REPLY_BUTTON_HEIGHT : CGFloat = 64.0
    private let HORIZONTAL_RULER_HEIGHT : CGFloat = 1.0
    
    private let CELL_MUG_AREA_HEIGHT: CGFloat = UIScreen.mainScreen().bounds.width
    private let CELL_MUG_TEXT_AREA_HEIGHT: CGFloat = 62
    
    var delegate: ChatViewController!
    var tableView: UITableView!
    var separatorView: UIView!
    var darkHorizontalRulerView: UIView!
    var replyButton: UIButton!
    
    // MARK: - Required initializers
    
    convenience override init() {
        self.init(frame: CGRect.zeroRect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubviews()
        self.makeConstraints()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: oldestUnreadMessageIndex, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Layout
    
    func addSubviews() {
        tableView = UITableView(frame: self.frame, style: .Plain)
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.registerClass(ChatTableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.separatorStyle = .None
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentOffset = CGPointMake(0, 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        self.addSubview(tableView)
        
        separatorView = UIView()
        separatorView.backgroundColor = UIColor.whiteColor()
        self.addSubview(separatorView)
        
        darkHorizontalRulerView = UIView()
        darkHorizontalRulerView.backgroundColor = UIColor.grayColor()
        self.addSubview(darkHorizontalRulerView)
        
        replyButton = UIButton()
        replyButton.contentMode = .Center
        replyButton.backgroundColor = UIColor.whiteColor()
        replyButton.addTarget(self, action: "didTapReplyButton", forControlEvents: UIControlEvents.TouchUpInside)
        replyButton.setImage(UIImage(named: "Reply"), forState: UIControlState.Normal)
        replyButton.sizeToFit()
        self.addSubview(replyButton)
    }
    
    func makeConstraints() {
        
        tableView.mas_makeConstraints( { (make) in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.separatorView.mas_top)
        })
        
        separatorView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.REPLY_BUTTON_TOP_MARGIN)
            make.bottom.equalTo()(self.darkHorizontalRulerView.mas_top)

        })
        
        darkHorizontalRulerView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.HORIZONTAL_RULER_HEIGHT)
            make.bottom.equalTo()(self.replyButton.mas_top)
        })
        
        replyButton.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.REPLY_BUTTON_HEIGHT)
            make.bottom.equalTo()(self)
        })
        
    }
    
    // MARK: - CustomNavigationBarDelegate
    
    func customNavigationBarDidTapLeftButton(navBar : CustomNavigationBar) {
        delegate?.chatViewDidTapBackButton(self)
    }
    
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:ChatTableViewCell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as ChatTableViewCell
        cell.message = mugs[indexPath.row]
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mugs.count;
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CELL_MUG_AREA_HEIGHT + CELL_MUG_TEXT_AREA_HEIGHT
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return NSLocalizedString("Delete", comment: "Delete")
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            mugs.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
        }
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Button Handlers
    
    func didTapReplyButton() {
        println("replyButtonTapped")
    }
}

protocol ChatViewDelegate {
    
    func chatViewDidTapBackButton(view: ChatView)
    
}