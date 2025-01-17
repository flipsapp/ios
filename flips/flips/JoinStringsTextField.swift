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

public let WORD_CHARACTER_PATTERN = "[\\w\']"

class JoinStringsTextField : UITextView, UITextViewDelegate {
    
    private let NUM_WORDS_LIMIT = 60
    
    private var joinedTextRanges : [NSRange] = [NSRange]()
    private let wordCharRegex = try! NSRegularExpression(pattern: WORD_CHARACTER_PATTERN, options: [])
    private var rangeThatWillChange: (range: NSRange, text: String)? = nil
    private let WHITESPACE: String = " "
    private let WHITESPACE_CHAR: Character = " "
    let DEFAULT_HEIGHT: CGFloat = 38.0
    let DEFAULT_LINE_HEIGHT: CGFloat = 20.0
    let JOINED_COLOR: UIColor = UIColor.flipOrange()
    
    weak var joinStringsTextFieldDelegate: JoinStringsTextFieldDelegate?
    
    var numberOfLines: Int {
        return Int(self.contentSize.height / self.font!.lineHeight)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero, textContainer: nil)
        self.returnKeyType = .Next
        self.delegate = self
        self.backgroundColor = UIColor.clearColor()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer!) {
        super.init(frame: frame, textContainer: textContainer)
        self.returnKeyType = .Next
    }
    
    required init?(coder: NSCoder) {
		super.init(coder: coder)
        self.returnKeyType = .Next
		self.delegate = self
    }
    
    func setupMenu() {
        let menuController = UIMenuController.sharedMenuController()
        let lookupMenu = UIMenuItem(title: NSLocalizedString("Join", comment: "Join"), action: #selector(JoinStringsTextField.joinStrings))
        menuController.menuItems = NSArray(array: [lookupMenu]) as? [UIMenuItem]
        menuController.update()
        menuController.setMenuVisible(true, animated: true)
    }
    
    func joinStrings(overrideColor: Bool) {
        let selectedTextRange: UITextRange = self.selectedTextRange!
        
        var string = [(String,NSRange)]()
        
        var posInit: Int = self.offsetFromPosition(self.beginningOfDocument, toPosition: selectedTextRange.start)
        var posEnd: Int = self.offsetFromPosition(self.beginningOfDocument, toPosition: selectedTextRange.end)
        
        let initialRange: NSRange? = NSMakeRange(posInit, posEnd-posInit)
        var tempInit: Int?
        var tempEnd: Int?
        var countSubstrings: Int? = 0
        
        let nsstring = self.text as NSString
        let fullRange = NSMakeRange(0, nsstring.length)
        nsstring.enumerateSubstringsInRange(fullRange, options: .ByComposedCharacterSequences) { (char: String?, range: NSRange, enclosingRange: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if (range.location == initialRange!.location) {
                tempInit = countSubstrings!
            }
            
            if (range.location + range.length == initialRange!.location + initialRange!.length) {
                tempEnd = countSubstrings! + 1
            }
                        
            string.append((char!, range))
            ++countSubstrings!
        }
        
        var rangeInit: Int = tempInit!
        var rangeEnd: Int = tempEnd!
    
        for i in rangeInit ..< rangeEnd {
            if (string[i].0 != WHITESPACE) {
                break
            }
            rangeInit += 1
            posInit += string[i].1.length
        }
        
        for (var i = rangeEnd-1; i >= rangeInit; i -= 1) {
            if (string[i].0 != WHITESPACE) {
                break
            }
            rangeEnd -= 1
            posEnd -= string[i].1.length
        }
        
        if (rangeInit == rangeEnd) {
            return
        }
        
        let firstCharIsSpecial = isSpecialCharacter(string[rangeInit].0)
        for (var i = rangeInit-1; i >= 0; i -= 1) {
            if (string[i].0 == WHITESPACE || isSpecialCharacter(string[i].0) != firstCharIsSpecial) {
                break
            }
            rangeInit -= 1
            posInit -= string[i].1.length
        }
        
        let lastCharIsSpecial = isSpecialCharacter(string[rangeEnd-1].0)
        for i in rangeEnd ..< string.count {
            if (string[i].0 == WHITESPACE || isSpecialCharacter(string[i].0) != lastCharIsSpecial) {
                break
            }
            rangeEnd += 1
            posEnd += string[i].1.length
        }
        
        var newRanges = [NSRange]()
        for i in 0 ..< self.joinedTextRanges.count {
            let range = self.joinedTextRanges[i]
            let intersection = NSIntersectionRange(NSMakeRange(posInit, posEnd-posInit), range)
            if (intersection.length > 0) {
                posInit = min(posInit, range.location)
                posEnd = max(posEnd, range.location+range.length)
                
                var joinedNSString = self.text as NSString
                joinedNSString = joinedNSString.substringWithRange(range)
                print(joinedNSString)
                //if there is an intersection with any previous range - we will remove the phrases in the sub-range
                //from the arrays used to keep track of appended and manually joined phrases. Unless the user just tapped
                //a stock flip suggestion that needs to be joined.
                if (!self.joinStringsTextFieldDelegate!.flipJustAppended!()){
                   self.joinStringsTextFieldDelegate?.removeFlipFromArrays!(joinedNSString as String)
                }
                
            } else {
                newRanges.append(range)
            }
        }
        newRanges.append(NSMakeRange(posInit, posEnd-posInit))
        self.joinedTextRanges = newRanges
        
        if (!overrideColor){
            self.updateColorOnJoinedTexts()
        }
        
        AnalyticsService.logWordsJoined()
    }
    
    private func updateColorOnJoinedTexts() {
        let selectedTextRange = self.selectedTextRange
        let attributedString = NSMutableAttributedString(string: self.text)
        let textLength = (self.text as NSString).length
        if (textLength <= 0) {
            return
        }
        
        let fullRange = NSMakeRange(0, textLength)
        attributedString.addAttribute(NSFontAttributeName, value: self.font!, range: fullRange)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: fullRange)
        
        let manuallyJoinedFlips = self.joinStringsTextFieldDelegate?.getManuallyJoinedFlips!()
        let flipsAppended = self.joinStringsTextFieldDelegate?.getAppendedFlips!()
        
        for joinedTextRange in joinedTextRanges {

            var joinedNSString = self.text as NSString
            joinedNSString = joinedNSString.substringWithRange(joinedTextRange)
            print(joinedNSString)
            
            
            func turnOrange(){
                if (NSIntersectionRange(fullRange, joinedTextRange).length == joinedTextRange.length) {
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: JOINED_COLOR, range: joinedTextRange)
                } else {
                    
                    print("Invalid joined text range \(joinedTextRange) on text field with length \(textLength)")
                }
            }
            func turnGreen(){
                if (NSIntersectionRange(fullRange, joinedTextRange).length == joinedTextRange.length) {
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.avacado(), range: joinedTextRange)
                } else {
                    
                    print("Invalid joined text range \(joinedTextRange) on text field with length \(textLength)")
                }
            }
            
            if ((!manuallyJoinedFlips!.contains(joinedNSString as String)) && (!flipsAppended!.contains(joinedNSString as String))){
                self.joinStringsTextFieldDelegate?.setManuallyJoined!(joinedNSString as String)
                self.joinStringsTextFieldDelegate?.setManualPlusAppended!(joinedNSString as String)
                turnOrange()
            } else if (manuallyJoinedFlips!.contains(joinedNSString as String)){
                turnOrange()
            } else if (flipsAppended!.contains(joinedNSString as String)){
                turnGreen()
            }
        }

        self.attributedText = attributedString
        self.selectedTextRange = selectedTextRange
    }
    
    private func getTextWords(text: String, limit: Int = -1) -> (words: [String], truncatedText: String) {
        var words = [String]()
        var textArray = Array(text.characters)
        var word: String = ""
        var index: Int = 0
        var limitIndex: Int = -1
        
        while (index < textArray.count) {
            if (limitIndex == -1 && limit >= 0 && words.count >= limit) {
                limitIndex = index
            }
            
            let partOfRange = isPartOfJoinedTextRanges(index)
            if (partOfRange.isPart) {
                if (word.characters.count > 0) {
                    words.append(word)
                    word = ""
                }
                words.append((text as NSString).substringWithRange(partOfRange.range!))
                index = partOfRange.range!.location+partOfRange.range!.length
            } else {
                let i = index++
                if (word.characters.count > 0 && (textArray[i] == WHITESPACE_CHAR || (isSpecialCharacter(Array(word.characters)[0]) != isSpecialCharacter(textArray[i])))) {
                    words.append(word)
                    word = ""
                }
                
                if (textArray[i] != WHITESPACE_CHAR) {
                    word.append(textArray[i])
                }
            }
        }
        
        if (word != "") {
            words.append(word)
        }
        
        var truncatedText = text
        if (limitIndex >= 0) {
            truncatedText = text.substringToIndex(text.startIndex.advancedBy(limitIndex))
        }

        return (words, truncatedText)
    }
    
    func getTextWords() -> [String] {
        self.resignFirstResponder()
        let textWords = self.getTextWords(self.text)
        self.becomeFirstResponder()
        
        return textWords.words
    }
    
    func isPartOfJoinedTextRanges(charIndex: Int) -> (isPart: Bool, range: NSRange?) {
        for textRange in self.joinedTextRanges {
            let posInit = textRange.location
            let posEnd = textRange.location + textRange.length
            if (posInit <= charIndex && charIndex < posEnd) {
                return (true, textRange)
            }
        }
        return (false, nil)
    }
    
    private func isSpecialCharacter(char: String) -> Bool {
        return wordCharRegex.numberOfMatchesInString(char, options: [], range: NSMakeRange(0, (char as NSString).length)) == 0
    }
    
    private func isSpecialCharacter(char: Character) -> Bool {
        let str = String(char)
        return wordCharRegex.numberOfMatchesInString(str, options: [], range: NSMakeRange(0, (str as NSString).length)) == 0
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(NSObject.cut(_:)) {
            return false
        }
            
        if action == #selector(NSObject.copy(_:)) {
            return true
        }
            
        if action == #selector(NSObject.paste(_:)) {
            return true
        }
            
        if action == Selector("_define:") {
            return false
        }
        
        if action == #selector(JoinStringsTextField.joinStrings) {
            return self.selectedTextCanBeJoined()
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    func selectedTextCanBeJoined() -> Bool {
        let selectedTextRange: UITextRange = self.selectedTextRange!
        
        let posInit: Int = self.offsetFromPosition(self.beginningOfDocument, toPosition: selectedTextRange.start)
        let posEnd: Int = self.offsetFromPosition(self.beginningOfDocument, toPosition: selectedTextRange.end)
        let selectionTextRange = NSMakeRange(posInit, posEnd-posInit)
        
        let textNSString = self.text as NSString
        let stringFromSelection = textNSString.substringWithRange(selectionTextRange)
        
        let arrayOfWords = FlipStringsUtil.splitFlipString(stringFromSelection)
        return arrayOfWords.count > 1
    }
    
    func handleMultipleLines(height: CGFloat) {
        if (numberOfLines > 1) {
            let y = self.contentSize.height-height
            let cursorRect = self.caretRectForPosition(self.selectedTextRange!.start)
            if (cursorRect.origin.y < y) {
                let cursorLineRect = CGRectMake(0, cursorRect.origin.y, self.contentSize.width, cursorRect.size.height)
                self.scrollRectToVisible(cursorLineRect, animated: false)
            } else {
                let lastLinesRect = CGRectMake(0, y, self.contentSize.width, height)
                self.scrollRectToVisible(lastLinesRect, animated: false)
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if (self.text.rangeOfString("\n") != nil) {
            self.text = self.text.stringByReplacingOccurrencesOfString("\n", withString: " ")
        }
        
        if let change = self.rangeThatWillChange {
            let range = change.range
            var newRanges = [NSRange]()
            for i in 0 ..< self.joinedTextRanges.count {
                var joinedRange = self.joinedTextRanges[i]
                if (range.location+range.length <= joinedRange.location) {
                    joinedRange.location += (change.text as NSString).length-range.length
                }
                
                if (range.length == 0) {
                    if (range.location < joinedRange.location || range.location >= joinedRange.location+joinedRange.length) {
                        newRanges.append(joinedRange)
                    }
                } else {
                    let intersection = NSIntersectionRange(range, self.joinedTextRanges[i])
                    if (intersection.length == 0) {
                        newRanges.append(joinedRange)
                    }
                }
            }
            self.joinedTextRanges = newRanges
            self.rangeThatWillChange = nil
            self.updateColorOnJoinedTexts()
        }
        
        let textWords = self.getTextWords(self.text, limit: NUM_WORDS_LIMIT)
        if (textWords.words.count > NUM_WORDS_LIMIT) {
            self.text = textWords.truncatedText // " ".join(words[0..<NUM_WORDS_LIMIT])
            
            let limitAlert = UIAlertView(title: NSLocalizedString("Flips"), message: NSLocalizedString("Flip Messages cannot be longer than 60 words."), delegate: nil, cancelButtonTitle: NSLocalizedString("OK"))
            limitAlert.show()
        }
        
        joinStringsTextFieldDelegate?.joinStringsTextField?(self, didChangeText: self.text)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.joinStringsTextFieldDelegate?.joinStringsTextFieldShouldReturn?(self)
                return
            })
            return false
        }
        
        self.rangeThatWillChange = (range,text)
        return true
    }
    
    func setWords(words: [String]) {
        _ = " "
        var text = "";
        var firstWord = true
        self.joinedTextRanges.removeAll(keepCapacity: false)
        for word in words {
            if (!firstWord) {
                text += " "
            } else {
                firstWord = false
            }
            if (isCompoundText(word)) {
                let compoundTextRange = NSMakeRange((text as NSString).length, (word as NSString).length)
                joinedTextRanges.append(compoundTextRange)
            }
            text += word
        }
        self.text = text
        self.updateColorOnJoinedTexts()
    }
    
    private func isCompoundText(word: String) -> Bool {
        let wordWithoutSpaces = word.removeWhiteSpaces()
        return wordWithoutSpaces != word
    }
    
    func appendJoinedTextRange(range: NSRange){
        self.joinedTextRanges.append(range)
    }
    
    func removeFromJoinedTextRanges(){
        self.joinedTextRanges.removeLast()
    }
    
}

// MARK: - View Delegate

@objc protocol JoinStringsTextFieldDelegate {
        
    optional func joinStringsTextFieldShouldReturn(joinStringsTextField: JoinStringsTextField) -> Bool
    
    optional func joinStringsTextField(joinStringsTextField: JoinStringsTextField, didChangeText: String!)
    
    optional func getAppendedFlips() -> [String]
    
    optional func getManuallyJoinedFlips() -> [String]
    
    optional func setManuallyJoined(flipText: String)
    
    optional func setManualPlusAppended(flipText: String)
    
    optional func removeFlipFromArrays(flipText: String)
    
    optional func flipJustAppended() -> Bool

}
