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

extension UITableViewCell {
    
    func removeSeparatorInsets() {
        // Remove separator insets in iOS 8
        if #available(iOS 8.0, *) {
            self.layoutMargins = UIEdgeInsetsZero
            self.preservesSuperviewLayoutMargins = false
        }
        self.separatorInset = UIEdgeInsetsZero
    }
}