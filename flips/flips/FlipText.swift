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

class FlipText {
    
    var position: Int!
    var text: String!
    var state: FlipState!
    var associatedFlipId: String?
    
    init(position: Int, text: String, state: FlipState) {
        self.position = position
        self.text = text
        self.state = state
    }
}

enum FlipState {
    case NotAssociatedAndNoResourcesAvailable
    case NotAssociatedButResourcesAvailable
    case AssociatedAndNoResourcesAvailable
    case AssociatedAndResourcesAvailable
}