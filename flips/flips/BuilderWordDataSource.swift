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

struct BuilderWordAttributes {
    static let WORD = "word"
    static let FROM_SERVER = "fromServer"
    static let ADDED_AT = "addedAt"
}

class BuilderWordDataSource: BaseDataSource {
    
    func cleanWordsFromServer() {
        let predicate = NSPredicate(format: "\(BuilderWordAttributes.FROM_SERVER) == true")
        BuilderWord.deleteAllMatchingPredicate(predicate, inContext: currentContext)
    }
    
    func addWords(words: [String], fromServer: Bool) {
        for word in words {
            let predicate = NSPredicate(format: "%K like %@", BuilderWordAttributes.WORD, word)
            let existingWord = BuilderWord.findAllWithPredicate(predicate, inContext: currentContext)
            if (existingWord.count == 0) {
                let builderWord = BuilderWord.createInContext(currentContext) as! BuilderWord
                builderWord.word = word
                builderWord.fromServer = fromServer
                builderWord.addedAt = NSDate()
            }
        }
    }
    
    func addWord(word: String, fromServer: Bool) -> Bool {
        var result: Bool!

        let predicate = NSPredicate(format: "%K like %@", BuilderWordAttributes.WORD, word)
        let existingWord = BuilderWord.findAllWithPredicate(predicate, inContext: currentContext)
        if (existingWord.count > 0) {
            result = false // DO NOT DUPLICATE
        } else {
            let builderWord = BuilderWord.createInContext(currentContext) as! BuilderWord
            builderWord.word = word
            builderWord.fromServer = fromServer
            builderWord.addedAt = NSDate()
            result = true
        }

        return result
    }
    
    func getWords() -> [BuilderWord] {
        return BuilderWord.findAllSortedBy(BuilderWordAttributes.ADDED_AT, ascending: false, inContext: currentContext) as! [BuilderWord]
    }
    
    func removeBuilderWordWithWord(word: String) {
        print("\nRemoving builder word: \(word)")
        let predicate = NSPredicate(format: "%K like %@", BuilderWordAttributes.WORD, word)
        BuilderWord.deleteAllMatchingPredicate(predicate, inContext: currentContext)
    }
}
