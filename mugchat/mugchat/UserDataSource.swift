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

private struct UserJsonParams {
    static let ID = "id"
    static let USERNAME = "username"
    static let FIRST_NAME = "firstName"
    static let LAST_NAME = "lastName"
    static let BIRTHDAY = "birthday"
    static let NICKNAME = "nickname"
    static let FACEBOOK_ID = "facebookID"
    static let PHOTO_URL = "photoUrl"
    static let PUBNUB_ID = "pubnubId"
    static let PHONE_NUMBER = "phoneNumber"
}

struct UserAttributes {
    static let USER_ID = "userID"
    static let FIRST_NAME = "firstName"
    static let LAST_NAME = "lastName"
    static let ME = "me"
    static let USER_CONTACT = "userContact"
}

public typealias UserSyncFinished = (Bool, NSError?) -> Void

class UserDataSource : BaseDataSource {
    
    // MARK: - CoreData Creator Methods
    
    private func createEntityWithJson(json: JSON) -> User {
        var entity: User! = User.MR_createEntity() as User
        
        self.fillUser(entity, withJsonData: json)
        
        return entity
    }
    
    // Entities in diferent context are not saved in the database. To save it, you need to merge the context where it was created.
    // Not sure if it will be used. Is here just like an example.
    private func createEntityInAnotherContextWithJson(json: JSON) -> User {
        var newContext = NSManagedObjectContext.MR_contextWithParent(NSManagedObjectContext.MR_context())
        
        println("Creating entity in new context: \(newContext)")
        var entity: User! = User.MR_createInContext(newContext) as User
        
        self.fillUser(entity, withJsonData: json)
        
        return entity
    }
    
    private func fillUser(user: User, withJsonData json: JSON) {
        if (user.userID != json[UserJsonParams.ID].stringValue) {
            println("Possible error. Will change user id from (\(user.userID)) to (\(json[UserJsonParams.ID].stringValue))")
        }
        
        user.userID = json[UserJsonParams.ID].stringValue
        user.username = json[UserJsonParams.USERNAME].stringValue
        user.firstName = json[UserJsonParams.FIRST_NAME].stringValue
        user.lastName = json[UserJsonParams.LAST_NAME].stringValue
        user.birthday = NSDate(dateTimeString: json[UserJsonParams.BIRTHDAY].stringValue)
        user.nickname = json[UserJsonParams.NICKNAME].stringValue
        user.facebookID = json[UserJsonParams.FACEBOOK_ID].stringValue
        user.photoURL = json[UserJsonParams.PHOTO_URL].stringValue
        user.pubnubID = json[UserJsonParams.PUBNUB_ID].stringValue
        user.phoneNumber = json[UserJsonParams.PHONE_NUMBER].stringValue
    }
    
    
    // MARK - Public Methods
    
    func createOrUpdateUserWithJson(json: JSON) -> User {
        let userID = json[UserJsonParams.ID].stringValue
        var user = self.getUserById(userID)
        
        if (user == nil) {
            user = self.createEntityWithJson(json)
        } else {
            self.fillUser(user!, withJsonData: json)
        }
        self.save()
        
        return user!
    }
    
    func retrieveUserWithId(id: String) -> User {
        var user = self.getUserById(id)
        
        if (user == nil) {
            println("User (\(id)) not found in the database and it mustn't happen. Check why he wasn't added to database yet.")
        }
        
        return user!
    }
    
    func syncUserData(callback: UserSyncFinished) {
        
        // TODO: sync my mugs with API
        
        // ONLY FOR TESTS
        var mug = Mug.createEntity() as Mug
        mug.mugID = "2"
        mug.word = "I"
        mug.backgroundURL = "https://s3.amazonaws.com/mugchat-pictures/09212b08-2904-4576-a93d-d686e9a3cba1.jpg"
        mug.owner = User.loggedUser()
        mug.isPrivate = true
        
        var mug2 = Mug.createEntity() as Mug
        mug2.mugID = "3"
        mug2.word = "Love"
        mug2.backgroundURL = "https://s3.amazonaws.com/mugchat-pictures/88a2af31-b250-4918-b773-9943a15406c7.jpg"
        mug2.owner = User.loggedUser()
        mug2.isPrivate = true
        
        var mug21 = Mug.createEntity() as Mug
        mug21.mugID = "30"
        mug21.word = "love"
        mug21.backgroundURL = "http://www.missaodespertar.org.br/imagens/imagem-5d0c1c481c3f5ec35d7632644c2142bf.jpg"
        mug21.owner = User.loggedUser()
        mug21.isPrivate = true
        
        var mug3 = Mug.createEntity() as Mug
        mug3.mugID = "4"
        mug3.word = "San Francisco"
        mug3.backgroundURL = "https://s3.amazonaws.com/mugchat-pictures/Screen+Shot+2014-10-10+at+11.27.00+AM.png"
        mug3.owner = User.loggedUser()
        mug3.isPrivate = true
        
        var user: User! = User.MR_createEntity() as User
        user.userID = "3"
        user.firstName = "Bruno"
        user.lastName = "User"
        user.phoneNumber = "+141512345678"
        user.photoURL = "http://upload.wikimedia.org/wikipedia/pt/9/9d/Maggie_Simpson.png"
        
        var mug4 = Mug.createEntity() as Mug
        mug4.mugID = "5"
        mug4.word = "San Francisco"
        mug4.backgroundURL = "http://baybridgeinfo.org/sites/default/files/images/background/ws/xws7.jpg.pagespeed.ic.ULYPGat4fH.jpg"
        mug4.owner = user
        mug4.isPrivate = true
        
        // NOT MY CONTACT
        var user3: User! = User.MR_createEntity() as User
        user3.userID = "5"
        user3.firstName = "Ecil"
        user3.lastName = "User"
        user3.phoneNumber = "+144423455555"
        user3.photoURL = "http://3.bp.blogspot.com/_339JZmAslb0/TG3x4LbfGeI/AAAAAAAAABU/QATFhgxPMvA/s200/Lisa_Simpson150.jpg"
        
        var contact: Contact! = Contact.MR_createEntity() as Contact
        contact.contactID = "1"
        contact.firstName = "Bruno"
        contact.lastName = "Contact"
        contact.phoneNumber = "+141512345678"
        contact.contactUser = user
        user.addUserContactObject(contact)
        
        // Simulating a user that is only contact on my agenda
        var contact2: Contact! = Contact.MR_createEntity() as Contact
        contact2.contactID = "2"
        contact2.firstName = "Fernando"
        contact2.lastName = "Contact"
        contact2.phoneNumber = "+144423456789"
        contact2.phoneType = "iPhone"

        var room: Room! = Room.MR_createEntity() as Room
        room.roomID = "1"
        room.pubnubID = "$2a$10$kSUvCzXQb83UYgMrxc1nYuthA16coqzVRrwyO2KcUzuSALXwURFqm"
        room.name = "Test"
        room.addParticipantsObject(user)
        room.addParticipantsObject(user3)
        
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
        // ONLY FOR TESTS
        
        callback(true, nil)
    }
    
    // Users from the App that are my contacts
    func getMyUserContacts() -> [User] {
        var predicate = NSPredicate(format: "((\(UserAttributes.ME) == false) AND (\(UserAttributes.USER_CONTACT).@count > 0))")
        var result = User.MR_findAllSortedBy("\(UserAttributes.FIRST_NAME)", ascending: true, withPredicate: predicate)
        return result as [User]
    }
    
    // MARK: - Private Getters Methods
    
    private func getUserById(id: String) -> User? {
        return User.findFirstByAttribute(UserAttributes.USER_ID, withValue: id) as? User
    }
}