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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Device : NSManagedObject

@property (nonatomic, retain) NSString * deviceID;
@property (nonatomic, retain) NSNumber * isVerified;
@property (nonatomic, retain) NSString * platform;
@property (nonatomic, retain) NSNumber * retryCount;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) User *user;

@end
