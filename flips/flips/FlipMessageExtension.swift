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

private let NOTIFICATION_PN_KEY = "pn_apns"
private let NOTIFICATION_KEY = "aps"
private let NOTIFICATION_ALERT_KEY = "alert"
private let NOTIFICATION_SOUND_KEY = "sound"
private let NOTIFICATION_SOUND_FILE = "default"
private let NOTIFICATION_CONTENT_KEY = "content-available"
private let NOTIFICATION_MESSAGE = "You received a new Flip message from"

public let NOTIFICATION_ROOM_KEY = "room_id"
public let NOTIFICATION_FLIP_MESSAGE_KEY = "flip_message_id"


public let MESSAGE_CONTENT = "content"
public let MESSAGE_DATA = "data"

public struct FormattedFlip {
    var flip: Flip
    var word: String
}

extension FlipMessage {

    var flipsEntries: Array<FlipEntry>? {
        get {
            let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
            let flipsEntries: NSMutableArray = NSMutableArray()
            if let testeEntries = self.entries as? Set<FlipEntry> {
                for entrie: FlipEntry in testeEntries {
                    flipsEntries.addObject(entrie)
                }
            }
            
            return flipsEntries.sortedArrayUsingDescriptors([sortDescriptor]) as? Array<FlipEntry>
        }
    }

    func addFlip(formatedFlip: FormattedFlip, inContext context: NSManagedObjectContext) {
        let nextEntryOrder = self.entries.count

        let entry: FlipEntry! = FlipEntry.createInContext(context) as? FlipEntry
        entry.order = nextEntryOrder
        entry.formattedWord = formatedFlip.word
        entry.flip = formatedFlip.flip.inContext(context) as? Flip
        entry.message = self

        self.addEntriesObject(entry)
    }
    
    func messagePhrase() -> String {
        let flipsEntries: [FlipEntry] = self.flipsEntries!
        let words = flipsEntries.map {
            (flipEntry) -> String in
            return flipEntry.formattedWord
        }

        return words.joinWithSeparator(" ")
    }
    
    func messageThumbnail(success: ((UIImage?) -> Void)? = nil) {
        if let firstEntry: FlipEntry = self.flipsEntries!.first {
            if let firstFlip: Flip = firstEntry.flip {
                if (firstFlip.thumbnailURL == nil || firstFlip.thumbnailURL == "") {
                    success?(UIImage.emptyFlipImage())
                    return
                }
                
                var cacheInstance: ThumbnailsDataSource!
                if (self.notRead.boolValue) {
                    cacheInstance = BlurredThumbnailsCache.sharedInstance
                } else {
                    cacheInstance = ThumbnailsCache.sharedInstance
                }

                cacheInstance.get(NSURL(string: firstFlip.thumbnailURL!)!,
                    success: { (url: String!, localPath: String!) in
                        let image = UIImage(contentsOfFile: localPath)
                        success?(image)
                    }, failure: { (url: String!, error: FlipError) in
                        print("Could not get thumbnail for flip \(firstFlip).")
                })
            }
        } else {
            success?(UIImage.emptyFlipImage())
        }
    }
    
    
    // MARK: - Message Handler
    
    func toJsonUsingFlipWords(flipWords: [FlipText]) -> Dictionary<String, AnyObject> {
        var dataDictionary = Dictionary<String, AnyObject>()
        
        dataDictionary.updateValue(MESSAGE_FLIPS_INFO_TYPE, forKey: MESSAGE_TYPE)
        dataDictionary.updateValue(self.from.userID, forKey: FlipMessageJsonParams.FROM_USER_ID)
        dataDictionary.updateValue(self.createdAt.toFormattedString(), forKey: FlipMessageJsonParams.SENT_AT)
        dataDictionary.updateValue(self.flipMessageID, forKey: FlipMessageJsonParams.FLIP_MESSAGE_ID)
        
        var notificationMessage = ""
        if let loggedUser = User.loggedUser() {
            let loggedUserFirstName = loggedUser.firstName
            notificationMessage = "\(NOTIFICATION_MESSAGE) \(loggedUserFirstName)"
        }
        
        var flipsDictionary = Array<Dictionary<String, String>>()
        let flipsEntries = self.flipsEntries
        for i in 0 ..< flipsEntries!.count {
            let flip: Flip = flipsEntries![i].flip
            let flipWord: FlipText = flipWords[i]
            
            var dic = Dictionary<String, String>()

            dic.updateValue(flip.flipID, forKey: FlipJsonParams.ID)
            dic.updateValue(flipWord.text, forKey: FlipJsonParams.WORD)
            dic.updateValue(flip.backgroundURL, forKey: FlipJsonParams.BACKGROUND_URL)
            dic.updateValue(flip.isPrivate.stringValue, forKey: FlipJsonParams.IS_PRIVATE)
            dic.updateValue(flip.thumbnailURL, forKey: FlipJsonParams.THUMBNAIL_URL)
            
            flipsDictionary.append(dic)
        }
        
        dataDictionary.updateValue(flipsDictionary, forKey: MESSAGE_CONTENT)
        
        var notificationDictionary = Dictionary<String, AnyObject>()
        notificationDictionary.updateValue(notificationMessage, forKey: NOTIFICATION_ALERT_KEY)
        notificationDictionary.updateValue(NOTIFICATION_SOUND_FILE, forKey: NOTIFICATION_SOUND_KEY)
        notificationDictionary.updateValue(1, forKey: NOTIFICATION_CONTENT_KEY)
        notificationDictionary.updateValue(1, forKey: "badge")
        
        var notificationApsDictionary = Dictionary<String, AnyObject>()
        notificationApsDictionary.updateValue(notificationDictionary, forKey: NOTIFICATION_KEY)
        notificationApsDictionary.updateValue(self.room.roomID, forKey: NOTIFICATION_ROOM_KEY)
        notificationApsDictionary.updateValue(self.flipMessageID, forKey: NOTIFICATION_FLIP_MESSAGE_KEY)
        
        var messageDictionary = Dictionary<String, AnyObject>()
        
        messageDictionary.updateValue(notificationApsDictionary, forKey: NOTIFICATION_PN_KEY)
        messageDictionary.updateValue(dataDictionary, forKey: MESSAGE_DATA)
        
        return messageDictionary
    }
}
