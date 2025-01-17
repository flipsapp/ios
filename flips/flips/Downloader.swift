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

let DOWNLOAD_FINISHED_NOTIFICATION_NAME: String = "download_finished_notification"
let DOWNLOAD_FINISHED_NOTIFICATION_PARAM_FLIP_KEY: String = "download_finished_notification_param_flip_key"
let DOWNLOAD_FINISHED_NOTIFICATION_PARAM_MESSAGE_KEY: String = "download_finished_notification_param_message_key"
let DOWNLOAD_FINISHED_NOTIFICATION_PARAM_FAIL_KEY: String = "download_finished_notification_param_fail_key"

public class Downloader : NSObject {
    
    let TIME_OUT_INTERVAL: NSTimeInterval = 60 //seconds
    
    // MARK: - Singleton Implementation
    
    public class var sharedInstance : Downloader {
        struct Static {
            static let instance : Downloader = Downloader()
        }
        return Static.instance
    }
    
    // MARK: - Download Public Methods

    func downloadTask(url: NSURL, localURL: NSURL, completion: ((success: Bool) -> Void), progress: ((Float) -> Void)? = nil, numberOfRetries: Int? = 3) {
        
        let tempFileName = "\(NSDate().timeIntervalSince1970)_\((localURL.path! as NSString).lastPathComponent)"
        let tempPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(tempFileName)
        let tempURL = NSURL(fileURLWithPath: tempPath)

        self.downloadTaskRetryingNumberOfTimes(numberOfRetries!, url: url, localURL: tempURL, success: { (responseObject) -> Void in
            var error: NSError? = nil
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.moveItemAtURL(tempURL, toURL: localURL)
            } catch let error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
            if let err = error {
                print("Error moving item to path \(localURL.path!), error \(err)")
            }
            completion(success: true)
        }, failure: { (error: NSError?) -> Void in
            print("Could not download data from URL: \(url.absoluteString) ERROR: \(error)")
            completion(success: false)
        }, progress: progress, latestError: nil)
    }
    
    private func downloadTaskRetryingNumberOfTimes(numberOfRetries: Int, url: NSURL, localURL: NSURL, success: (AnyObject?) -> Void, failure: (NSError?) -> Void, progress: ((Float) -> Void)? = nil, latestError: NSError?) {
        if (latestError != nil && numberOfRetries <= 0) {
            failure(latestError)
        } else {
            let request = NSMutableURLRequest(URL: url)
            request.timeoutInterval = TIME_OUT_INTERVAL
            
            let operation = AFHTTPRequestOperation(request: request)
            operation.outputStream = NSOutputStream(URL: localURL, append: false)
            
            operation.setCompletionBlockWithSuccess({ (operation, responseObject) -> Void in
                success(responseObject)
            }, failure: { (operation, error) -> Void in
                print("Download failed - retries remaining: \(numberOfRetries - 1)")
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(localURL)
                } catch _ {
                }

                if (numberOfRetries > 0) {
                    self.downloadTaskRetryingNumberOfTimes(numberOfRetries - 1, url: url, localURL: localURL, success: success, failure: failure, progress: progress, latestError: error)
                } else {
                    failure(error)
                }
            })
            
            if (progress != nil) {
                operation.setDownloadProgressBlock { (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
                    progress?(Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                    return
                }
            }
            
            operation.start()
        }
    }
}
