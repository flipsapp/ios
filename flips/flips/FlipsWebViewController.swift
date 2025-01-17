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

class FlipsChatWebViewController: FlipsViewController {
    
    var flipChatWebView: FlipsWebView!
    var webTitle: String!
    
    init(view: FlipsWebView, title: String) {
        super.init(nibName: nil, bundle: nil)
        self.flipChatWebView = view
        self.webTitle = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.view = self.flipChatWebView
        self.setupWhiteNavBarWithBackButton(NSLocalizedString(self.webTitle, comment: self.webTitle))
        self.flipChatWebView.viewDidLoad()
    }
}
