//
//  NewFlipViewController.swift
//  mugchat
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

private let STORYBOARD = "NewFlip"


class NewFlipViewController: MugChatViewController,
    JoinStringsTextFieldDelegate,
    NSFetchedResultsControllerDelegate,
    UIAlertViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UITextViewDelegate {
    
    // MARK: - Constants
    
    private let CANCEL_MESSAGE = NSLocalizedString("This will delete any text you have written for this message.  Do you wish to delete this message?", comment: "Cancel message")
    private let CANCEL_TITLE = NSLocalizedString("Delete Message", comment: "Delete Message")
    private let DELETE = NSLocalizedString("Delete", comment: "Delete")
    private let NO = NSLocalizedString("No", comment: "No")
    private let TITLE = NSLocalizedString("New Flip", comment: "New Flip")
    
    // MARK: - Class methods
    
    class func instantiateNavigationController() -> UINavigationController {
        let storyboard = UIStoryboard(name: STORYBOARD, bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as UINavigationController
        navigationController.topViewController.modalPresentationStyle = UIModalPresentationStyle.FullScreen
        
        return navigationController
    }
    
    // MARK: - Instance variables
    
    @IBOutlet weak var flipTextField: JoinStringsTextField!
    @IBOutlet weak var flipTextFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonAction: UIButton!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var toTextView: UITextView!
    @IBOutlet weak var toTextViewHeightConstraint: NSLayoutConstraint!
    
    let contactDataSource = ContactDataSource()
    var fetchedResultsController: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupWhiteNavBarWithCancelButton(TITLE)
        self.setNeedsStatusBarAppearanceUpdate()
        self.automaticallyAdjustsScrollViewInsets = false
        self.searchTableView.registerNib(UINib(nibName: ContactTableViewCellIdentifier, bundle: nil), forCellReuseIdentifier: ContactTableViewCellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.BlackOpaque
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        self.updateHeightConstraintIfNeeded(self.flipTextFieldHeightConstraint, view: self.flipTextField)
        self.updateHeightConstraintIfNeeded(self.toTextViewHeightConstraint, view: self.toTextView)
    }
    
    // MARK: - Private methods
    
    private func updateContactSearch() {
        if self.toTextView.text.isEmpty {
            self.fetchedResultsController = nil
        } else {
            self.fetchedResultsController = self.contactDataSource.fetchedResultsController(self.toTextView.text, delegate: self)
        }
        
        self.updateSearchTableView()
    }
    
    private func updateHeightConstraintIfNeeded(heightConstraint: NSLayoutConstraint, view: UIScrollView) {
        let maxHeight = CGRectGetHeight(self.view.frame)/2
        var neededHeight = view.contentSize.height
        
        if (neededHeight > maxHeight) {
            neededHeight = maxHeight
            view.contentOffset = CGPointZero
        }
        
        if (neededHeight != heightConstraint.constant) {
            heightConstraint.constant = neededHeight
        }
    }
    
    private func updateSearchTableView() {
        if let contacts = self.fetchedResultsController?.fetchedObjects {
            self.searchTableView.hidden = (contacts.count == 0)
        } else {
            self.searchTableView.hidden = true
        }
        
        self.searchTableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func nextButtonAction(sender: UIButton) {
        
    }
    
    override func closeButtonTapped() {
        if !flipTextField.hasText() {
            super.closeButtonTapped()
        } else {
            let alertView = UIAlertView(title: CANCEL_TITLE, message: CANCEL_MESSAGE, delegate: self, cancelButtonTitle: NO, otherButtonTitles: DELETE)
            alertView.show()
        }
    }
    
    // MARK: - JointStringsTextFieldDelegate
    
    func joinStringsTextFieldNeedsToHaveItsHeightUpdated(joinStringsTextField: JoinStringsTextField!) {
        self.view.setNeedsUpdateConstraints()
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.updateSearchTableView()
    }
    
    // MARK: - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            super.closeButtonTapped()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = self.fetchedResultsController?.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let contact = self.fetchedResultsController?.objectAtIndexPath(indexPath) as Contact
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCellIdentifier, forIndexPath: indexPath) as ContactTableViewCell;
        cell.nameLabel.text = "\(contact.firstName) \(contact.lastName)"
        cell.photoView.initials = "\(contact.firstName[contact.firstName.startIndex])\(contact.lastName[contact.lastName.startIndex])"
        
        if let user = contact.contactUser {
            // Flips user
            cell.photoView.borderColor = .mugOrange()
            
            if let photoURLString = user.photoURL {
                if let url = NSURL(string: photoURLString) {
                    cell.photoView.setImageWithURL(url)
                }
            }
        } else {
            // not a Flips user
            cell.numberLabel?.text = contact.phoneNumber
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    // MARK: - UITextViewDelegate
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        } else if (text.rangeOfString("\n") != nil) {
            let replacementText: String = text.stringByReplacingOccurrencesOfString("\n", withString: "")
            textView.text = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: replacementText)
            return false
        }
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        self.view.setNeedsUpdateConstraints()
        
        if (textView == self.toTextView) {
            self.updateContactSearch()
        }
    }
}
