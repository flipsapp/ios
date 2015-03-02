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

class BuilderViewController : ComposeViewController, BuilderIntroductionViewControllerDelegate, BuilderAddWordTableViewControllerDelegate {
    
    private var builderIntroductionViewController: BuilderIntroductionViewController!

    
    // MARK: - Initialization Methods
    
    init() {
        super.init(composeTitle: NSLocalizedString("Builder", comment: "Builder"))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        self.loadBuilderWords()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if (!DeviceHelper.sharedInstance.didUserAlreadySeenBuildIntroduction()) {
            DeviceHelper.sharedInstance.setBuilderIntroductionShown(true)
            self.showIntroduction()
        }
    }
    
    override func shouldShowPreviewButton() -> Bool {
        return false
    }
    
    override func canShowMyFlips() -> Bool {
        return false
    }
    
    override func shouldShowPlusButtonInWords() -> Bool {
        return true
    }
    
    
    // MARK: - Load BuilderWords Methods
    
    private func loadBuilderWords() {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        let builderWordDataSource = BuilderWordDataSource()
        let builderWords = builderWordDataSource.getWords()
        
        words = Array<String>()
        for builderWord in builderWords {
            words.append(builderWord.word)
        }
        
        ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
        self.initFlipWords(words)
    }
    
    
    // MARK: - Builder Introduction Methods
    
    func showIntroduction() {
        builderIntroductionViewController = BuilderIntroductionViewController(viewBackground: self.view.snapshot())
        builderIntroductionViewController.view.alpha = 0.0
        builderIntroductionViewController.delegate = self
        self.view.addSubview(builderIntroductionViewController.view)
        self.addChildViewController(builderIntroductionViewController)
        
        self.builderIntroductionViewController.view.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.view)
            make.bottom.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
        }
        
        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.navigationController?.navigationBar.alpha = 0.001
            self.builderIntroductionViewController.view.alpha = 1.0
        })
    }
    
    func builderIntroductionViewControllerDidTapOkSweetButton(builderIntroductionViewController: BuilderIntroductionViewController!) {
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.navigationController?.navigationBar.alpha = 1.0
            self.builderIntroductionViewController.view.alpha = 0.0
        }) { (completed) -> Void in
            self.view.sendSubviewToBack(self.builderIntroductionViewController.view)
        }
    }
    
    
    // MARK: - FlipMessageWordListView Delegate
    
    override func flipMessageWordListViewDidTapAddWordButton(flipMessageWordListView: FlipMessageWordListView) {
        var addWordWords = Array<String>()
        for flipWord in self.flipWords {
            println(" flipWord: \(flipWord.text) - \(flipWord.state)")
            if (flipWord.state == FlipState.NotAssociatedAndNoResourcesAvailable) {
                addWordWords.append(flipWord.text)
            }
        }
        
        let builderAddWordTableViewController = BuilderAddWordTableViewController(words: addWordWords)
        builderAddWordTableViewController.delegate = self
        self.navigationController?.pushViewController(builderAddWordTableViewController, animated: true)
    }

    
    // MARK: - BuilderAddWordTableViewControllerDelegate
    
    func builderAddWordTableViewControllerDelegate(tableViewController: BuilderAddWordTableViewController, finishingWithChanges hasChanges: Bool) {
        if (hasChanges) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                self.loadBuilderWords()
                if (self.words.count > 0) {
                    self.highlightedWordIndex = 0
                    self.reloadMyFlips()
                    self.updateFlipWordsState()
                    self.showContentForHighlightedWord()
                } 
            })
        }
    }
}