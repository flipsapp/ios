//
//  AppSettings.swift
//  flips
//
//  Created by Paulo Michels on 4/9/15.
//
//

import Foundation

class AppSettings {
    
    class var sharedInstance: AppSettings {
        struct Static {
            static let instance: AppSettings = AppSettings()
        }
        return Static.instance
    }

    class func currentSettings() -> AppSettings {
        return sharedInstance;
    }
    
    private var envSettings: NSDictionary
    
    init(env: String) {
        let appSettings = NSBundle.mainBundle().infoDictionary!["AppSettings"] as NSDictionary
        envSettings = appSettings[env] as NSDictionary
    }
    
    convenience init() {
        var currentEnv = "QA"
        
        #if DEV
            currentEnv = "DEV"
        #endif

        #if PROD
            currentEnv = "PROD"
        #endif

        self.init(env: currentEnv)
    }
    
    func ServerURL() -> String {
        return envSettings["ServerURL"] as String
    }

    func PubNubPublishKey() -> String {
        return envSettings["PubNubPublishKey"] as String
    }
    
    func PubNubSubscribeKey() -> String {
        return envSettings["PubNubSubscribeKey"] as String
    }
    
    func PubNubSecretKey() -> String {
        return envSettings["PubNubSecretKey"] as String
    }
    
}