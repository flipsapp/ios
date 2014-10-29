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

struct ContactAttributes {
    static let FIRST_NAME = "firstName"
    static let LAST_NAME = "lastName"
    static let PHONE_NUMBER = "phoneNumber"
    static let PHONE_TYPE = "phoneType"
    static let CONTACT_USER = "contactUser"
}


class ContactDataSource : BaseDataSource {
    
    // MARK: - CoreData Creator Methods
    
    private func createEntityWith(firstName: String, lastName: String, phoneNumber: String, phoneType: String) -> Contact {
        var entity: Contact! = Contact.MR_createEntity() as Contact

        entity.createdAt = NSDate()
        self.fillContact(entity, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, phoneType: phoneType)
        
        return entity
    }
    
    private func fillContact(contact: Contact, firstName: String, lastName: String, phoneNumber: String, phoneType: String) {
        contact.firstName = firstName
        contact.lastName = lastName
        contact.phoneNumber = phoneNumber
        contact.phoneType = phoneType
        contact.updatedAt = NSDate()
    }
    
    
    // MARK: - Public Methods
    
    func createOrUpdateContactWith(firstName: String, lastName: String, phoneNumber: String, phoneType: String) -> Contact {

        var contact = self.getContactBy(firstName, lastName: lastName, phoneNumber: phoneNumber, phoneType: phoneType)
        
        if (contact == nil) {
            contact = self.createEntityWith(firstName, lastName: lastName, phoneNumber: phoneNumber, phoneType: phoneType)
        } else {
            self.fillContact(contact!, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, phoneType: phoneType)
        }
        self.save()
        
        return contact!
    }
    
    func getMyContacts() -> [Contact] {
        return Contact.findAllSortedBy("firstName", ascending: true, withPredicate: NSPredicate(format: "(\(ContactAttributes.CONTACT_USER) == nil)")) as [Contact]
    }
    
    
    // MARK: - Private Methods
    
    private func getContactBy(firstName: String?, lastName: String?, phoneNumber: String?, phoneType: String?) -> Contact? {
        var predicateValue = ""
        
        if (firstName != nil) {
            var value = firstName!
            predicateValue = "(\(ContactAttributes.FIRST_NAME) == \(value))"
        }
        
        if (lastName != nil) {
            var value = lastName!
            if (predicateValue.isEmpty) {
                predicateValue = "(\(ContactAttributes.LAST_NAME) == \(value))"
            } else {
                predicateValue = "\(predicateValue) AND (\(ContactAttributes.LAST_NAME) == \(value))"
            }
        }
        
        if (phoneNumber != nil) {
            var value = phoneNumber!
            if (predicateValue.isEmpty) {
                predicateValue = "(\(ContactAttributes.PHONE_NUMBER) == \(value))"
            } else {
                predicateValue = "\(predicateValue) AND (\(ContactAttributes.PHONE_NUMBER) == \(value))"
            }
        }
        
        if (phoneType != nil) {
            var value = phoneType!
            if (predicateValue.isEmpty) {
                predicateValue = "(\(ContactAttributes.PHONE_TYPE) == \(value))"
            } else {
                predicateValue = "\(predicateValue) AND (\(ContactAttributes.PHONE_TYPE) == \(value))"
            }
        }

        return Contact.findFirstWithPredicate(NSPredicate(format: predicateValue)) as? Contact
    }
}