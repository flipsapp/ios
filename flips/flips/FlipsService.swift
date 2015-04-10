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

public typealias OperationSuccessCallback = (AFHTTPRequestOperation!, AnyObject!) -> Void
public typealias OperationFailureCallback = (AFHTTPRequestOperation, NSError) -> Void

public class FlipsService : NSObject {

    var HOST = AppSettings.currentSettings().ServerURL()
    
    private let BACKEND_FORBIDDEN_REQUEST = 403
    private let BACKEND_TIMED_OUT: Int = 408
    private let BACKEND_TIMED_OUT_MESSAGE: String = "The request timed out."
    
    
    // MARK: - Service Methods
    
	func post(urlString: String, parameters: AnyObject?, success: OperationSuccessCallback, failure: OperationFailureCallback) -> AFHTTPRequestOperation {

        let request: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        request.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer

        return request.POST(urlString,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                success(operation, responseObject)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                if (self.isForbiddenRequest(error)) {
                    self.sendBlockedUserNotification()
                } else if (self.isTimedOutError(error)) {
                    failure(AFHTTPRequestOperation(), self.errorForTimedOutError())
                } else {
                    failure(operation, error)
                }
            }
        )
    }

    func post(urlString: String, parameters: AnyObject?, constructingBodyWithBlock: (AFMultipartFormData!) -> Void, success: OperationSuccessCallback, failure: OperationFailureCallback) -> AFHTTPRequestOperation {
        let request: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        request.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer

        return request.POST(urlString,
            parameters: parameters,
            constructingBodyWithBlock: constructingBodyWithBlock,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                success(operation, responseObject)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                if (self.isForbiddenRequest(error)) {
                    self.sendBlockedUserNotification()
                } else if (self.isTimedOutError(error)) {
                    failure(AFHTTPRequestOperation(), self.errorForTimedOutError())
                } else {
                    failure(operation, error)
                }
            }
        )
    }
    
    func get(urlString: String, parameters: AnyObject?, success: OperationSuccessCallback, failure: OperationFailureCallback) -> AFHTTPRequestOperation {
        let request: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        request.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer

        return request.GET(urlString,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                success(operation, responseObject)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                if (self.isForbiddenRequest(error)) {
                    self.sendBlockedUserNotification()
                } else if (self.isTimedOutError(error)) {
                    failure(AFHTTPRequestOperation(), self.errorForTimedOutError())
                } else {
                    failure(operation, error)
                }
            }
        )
    }
    
    
    // MARK: - Auxiliary Methods
    
    private func isForbiddenRequest(error: NSError!) -> Bool {
        println(error.localizedDescription)
        return (error.localizedDescription.rangeOfString(String(BACKEND_FORBIDDEN_REQUEST)) != nil)
    }
    
    private func isTimedOutError(error: NSError) -> Bool {
        return (error.description.rangeOfString(BACKEND_TIMED_OUT_MESSAGE) != nil)
    }
    
    private func errorForTimedOutError() -> NSError {
        let message = NSLocalizedString("The request timed out. Please check your internet connection.")
        return NSError(domain: message, code: BACKEND_TIMED_OUT, userInfo: ["NSLocalizedDescriptionKey" : message])
    }
    
    private func sendBlockedUserNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(POP_TO_ROOT_NOTIFICATION_NAME, object: nil, userInfo: nil)
    }
}