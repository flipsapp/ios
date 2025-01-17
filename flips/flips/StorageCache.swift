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

public class StorageCache {

    public typealias CacheSuccessCallback = (String!, String!) -> Void
    public typealias CacheFailureCallback = (String!, FlipError) -> Void
    public typealias CacheProgressCallback = (Float) -> Void
    public typealias DownloadFinishedCallbacks = (success: CacheSuccessCallback?, failure: CacheFailureCallback?, progress: CacheProgressCallback?)
    
    public enum CacheGetResponse {
        case DATA_IS_READY
        case DOWNLOAD_WILL_START
        case INVALID_URL
    }
    
    private let cacheDirectoryPath: NSURL
    private let scheduleCleanup: () -> Void
    private let cacheJournal: CacheJournal
    private let cacheQueue: dispatch_queue_t
    private let downloadSyncQueue: dispatch_queue_t
    private var downloadInProgressURLs: Dictionary<String, [DownloadFinishedCallbacks]>
    private var cacheWasCleared: ThreadSafe<Bool>

    var numberOfRetries: Int = 3

    var sizeInBytes: Int64 {
        return self.cacheJournal.cacheSize
    }
    
    init(cacheID: String, cacheDirectoryName: String, scheduleCleanup: () -> Void) {
        self.scheduleCleanup = scheduleCleanup
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .LocalDomainMask, true)
        let applicationSupportDirPath = paths.first! 
        let applicationSupportDirAbsolutePath = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(applicationSupportDirPath)
        let cacheDirectoryAbsolutePath = (applicationSupportDirAbsolutePath as NSString).stringByAppendingPathComponent(cacheDirectoryName)
        self.cacheDirectoryPath = NSURL(fileURLWithPath: cacheDirectoryAbsolutePath)
        let journalName = (self.cacheDirectoryPath.path! as NSString).stringByAppendingPathComponent("\(cacheID).cache")
        self.cacheJournal = CacheJournal(absolutePath: journalName)
        self.cacheQueue = dispatch_queue_create(cacheID, nil)
        self.downloadSyncQueue = dispatch_queue_create("\(cacheID)DownloadQueue", nil)
        self.downloadInProgressURLs = Dictionary<String, [DownloadFinishedCallbacks]>()
        self.cacheWasCleared = ThreadSafe<Bool>(false)
        self.initCacheDirectory()
        self.cacheJournal.open()
    }
    
    private func initCacheDirectory() {
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = true
        
        var error: NSError? = nil
        
        if (fileManager.fileExistsAtPath(cacheDirectoryPath.path!, isDirectory: &isDirectory)) {
            print("Directory exists: \(cacheDirectoryPath)")
        } else {
            do {
                try fileManager.createDirectoryAtPath(cacheDirectoryPath.path!, withIntermediateDirectories: true, attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            if (error != nil) {
                print("Error creating cache dir: \(error)")
            } else {
                print("Directory '\(cacheDirectoryPath)' created!")
            }
        }
        
        do {
            try cacheDirectoryPath.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        } catch let error1 as NSError {
            error = error1
        }
        if (error != nil) {
            print("Error excluding cache dir from backup: \(error)")
        }
    }

    /**
    Asynchronously retrieves an asset. Whenever it's available, the success function is called.
    If the asset is not in the cache by the time this function is called, it's downloaded and
    inserted in the cache before its local path is passed to the success function. If some error occurs
    (e.g. not in cache and no internet connection), the failure function is called with some
    error description. While the asset is being downloaded the progress callback will be called to indicate
    the progress of the operation.
    
    - parameter remoteURL: The URL from which the asset will be downloaded if a cache miss has occurred. This path also uniquely identifies the asset.
    - parameter success:   A function that is called when the asset is successfully available.
    - parameter failure:   A function that is called when the asset could not be retrieved.
    - parameter progress:  A function that is called while the asset is being retrieved to indicate progress.
    */
    func get(remoteURL: NSURL, success: CacheSuccessCallback?, failure: CacheFailureCallback?, progress: CacheProgressCallback? = nil) -> CacheGetResponse {
        self.cacheWasCleared.value = false
        let localPath = self.createLocalPath(remoteURL)
        if (self.cacheHit(localPath)) {
            dispatch_async(self.cacheQueue) {
                progress?(1.0)
                success?(remoteURL.absoluteString, localPath)
                self.cacheJournal.updateEntry(localPath)
                return
            }
            return CacheGetResponse.DATA_IS_READY
        }

        var downloadedAlreadyStarted = false
        
        dispatch_sync(self.downloadSyncQueue) {
            if (self.downloadInProgressURLs[localPath] != nil) {
                self.downloadInProgressURLs[localPath]!.append((success: success, failure: failure, progress: progress))
                downloadedAlreadyStarted = true
            }
            
            if (!downloadedAlreadyStarted) {
                self.downloadInProgressURLs[localPath] = [DownloadFinishedCallbacks]()
                self.downloadInProgressURLs[localPath]!.append((success: success, failure: failure, progress: progress))
            }
        }
        
        if (downloadedAlreadyStarted) {
            return CacheGetResponse.DOWNLOAD_WILL_START
        }
        
        Downloader.sharedInstance.downloadTask(remoteURL,
            localURL: NSURL(fileURLWithPath: localPath),
            completion: { (success) -> Void in
                if (self.cacheWasCleared.value) {
                    return
                }
                
                if (success) {
                    dispatch_async(self.cacheQueue) {
                        self.cacheJournal.insertNewEntry(localPath)
                        self.scheduleCleanup()
                    }
                }
                
                var callbacksArray: [DownloadFinishedCallbacks]? = nil
                
                dispatch_sync(self.downloadSyncQueue) {
                    callbacksArray = self.downloadInProgressURLs[localPath]
                    self.downloadInProgressURLs[localPath] = nil
                }
                
                if (callbacksArray == nil) {
                    print("Local path (\(localPath)) has been downloaded but we already cleaned up its callbacks.")
                    return
                }
                
                for callbacks in callbacksArray! {
                    if (success) {
                        callbacks.success?(remoteURL.absoluteString, localPath)
                    } else {
                        callbacks.failure?(remoteURL.absoluteString, FlipError(error: "Error downloading media file", details: nil))
                    }
                }
            },
            progress: { (downloadProgress) -> Void in
                if (self.cacheWasCleared.value) {
                    return
                }
                
                var callbacksAlreadyCleaned = false
                var progressCallbacks = [CacheProgressCallback?]()
                
                dispatch_sync(self.downloadSyncQueue) {
                    if (self.downloadInProgressURLs[localPath] == nil) {
                        callbacksAlreadyCleaned = true
                    } else {
                        for callbacks in self.downloadInProgressURLs[localPath]! {
                            progressCallbacks.append(callbacks.progress)
                        }
                    }
                }
                
                if (callbacksAlreadyCleaned) {
                    print("Local path (\(localPath)) is being downloaded but we already cleaned up its callbacks.")
                    return
                }
                
                for progress in progressCallbacks {
                    progress?(downloadProgress)
                }
            },
            numberOfRetries: self.numberOfRetries
        )
        
        return CacheGetResponse.DOWNLOAD_WILL_START
    }
    
    func has(remoteURL: NSURL) -> Bool {
        let localPath = self.createLocalPath(remoteURL)
        return self.cacheHit(localPath)
    }
    
    /**
    Inserts the data into the cache, identified by its remote URL. This operation is synchronous.
    
    - parameter remoteURL: The path from which the asset will be downloaded if a cache miss has occurred. This path also uniquely identifies the asset.
    - parameter srcPath:   The path where the asset is locally saved. The asset will be moved to the cache.
    */
    func put(remoteURL: NSURL, localPath srcPath: String) -> Void {
        self.cacheWasCleared.value = false
        let toPath = self.createLocalPath(remoteURL)
        
        if (!self.cacheHit(toPath)) {
            dispatch_async(self.cacheQueue) {
                var error: NSError? = nil
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.moveItemAtPath(srcPath, toPath: toPath)
                } catch let error1 as NSError {
                    error = error1
                } catch {
                    fatalError()
                }
                if (error != nil) {
                    print("Error move asset to the cache dir: \(error)")
                }
                self.cacheJournal.insertNewEntry(toPath)
                self.scheduleCleanup()
            }
        }
    }
    
    /**
    Inserts the data into the cache, identified by its remote URL. This operation is synchronous.
    
    - parameter remoteURL: The path from which the asset will be downloaded if a cache miss has occurred. This path also uniquely identifies the asset.
    - parameter data:      The actual asset that is going to be inserted into the cache.
    */
    func put(remoteURL: NSURL, data: NSData) -> String {
        self.cacheWasCleared.value = false
        let localPath = self.createLocalPath(remoteURL)
        
        if (!self.cacheHit(localPath)) {
            dispatch_async(self.cacheQueue) {
                let fileManager = NSFileManager.defaultManager()
                fileManager.createFileAtPath(localPath, contents: data, attributes: nil)
                self.cacheJournal.insertNewEntry(localPath)
                self.scheduleCleanup()
            }
        }
        return localPath
    }
    
    func getLRUSizesAndTimestamps(sizeInBytes: Int64) -> ArraySlice<(UInt64,Int)> {
        var slice: ArraySlice<(UInt64,Int)>!
        dispatch_sync(self.cacheQueue) {
            slice = self.cacheJournal.getLRUSizesAndTimestamps(sizeInBytes)
        }
        return slice
    }
    
    func removeLRUEntries(count: Int) -> Void {
        dispatch_async(self.cacheQueue) {
            let leastRecentlyUsed = self.cacheJournal.getLRUEntries(count)
            let fileManager = NSFileManager.defaultManager()
            for fileName in leastRecentlyUsed {
                let path = (self.cacheDirectoryPath.path! as NSString).stringByAppendingPathComponent(fileName)
                do {
                    try fileManager.removeItemAtPath(path)
                }
                catch let error as NSError {
                    print("Could not remove file \(fileName). Error: \(error)")
                }
            }
            
            self.cacheJournal.removeLRUEntries(leastRecentlyUsed.count)
        }
    }
    
    func clear() -> Void {
        dispatch_async(self.cacheQueue) {
            let entries = self.cacheJournal.getEntries()
            let fileManager = NSFileManager.defaultManager()
            for fileName in entries {
                let path = (self.cacheDirectoryPath.path! as NSString).stringByAppendingPathComponent(fileName)
                
                do {
                    try fileManager.removeItemAtPath(path)
                }
                catch let error as NSError {
                    print("Could not remove file \(fileName). Error: \(error)")
                }
            }
            
            self.cacheJournal.clear()
            self.downloadInProgressURLs.removeAll(keepCapacity: false)
            self.cacheWasCleared.value = true
        }
    }
    
    private func createLocalPath(remoteURL: NSURL) -> String {
        //I think the best approach here would be to generate a Hash based on the actual data,
        //but for now we're just using the last path component.
        return (cacheDirectoryPath.path! as NSString).stringByAppendingPathComponent(remoteURL.lastPathComponent!)
    }
    
    private func cacheHit(localPath: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(localPath)
    }
    
}