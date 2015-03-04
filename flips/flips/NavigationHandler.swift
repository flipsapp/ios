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

public let POP_TO_ROOT_NOTIFICATION_NAME = "POP_TO_ROOT_NOTIFICATION_NAME"

public class NavigationHandler : NSObject {
    
    public class var sharedInstance : NavigationHandler {
        struct Static {
            static let instance : NavigationHandler = NavigationHandler()
        }
        return Static.instance
    }
    
    func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPopToRootViewControllerNotificationReceived:", name: POP_TO_ROOT_NOTIFICATION_NAME, object: nil)
    }
    
    func onPopToRootViewControllerNotificationReceived(notification: NSNotification) {
        if let keyWindow = UIApplication.sharedApplication().keyWindow {
            if let rootViewController = keyWindow.rootViewController {
                println(">*>*>*>*>* TYPE: \(rootViewController.dynamicType.description())")
                if (rootViewController is LoginViewController) {
                    println("I'm in the LoginViewController")
                }
                if (rootViewController is SplashScreenViewController) {
                    println("I'm in the SplashScreenViewController")
                }
                if (rootViewController is UINavigationController) {
                    var rootNavigationViewController: UINavigationController = rootViewController as UINavigationController
                    
                    AuthenticationHelper.sharedInstance.logout()
                    if (rootNavigationViewController.visibleViewController.navigationController != rootNavigationViewController) {
                        println("*1*1*1")
                        rootNavigationViewController.popToRootViewControllerAnimated(false)
                        rootNavigationViewController.visibleViewController.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        println("*2*2*2")
                        println(rootNavigationViewController)
                        //rootNavigationViewController.popToRootViewControllerAnimated(true)
                        rootNavigationViewController.navigationController?.pushViewController(LoginViewController(), animated: true)
                    }
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        let alertView = UIAlertView(title: NSLocalizedString("Session Expired"), message: NSLocalizedString("Please try to log in again. If the issue persists, please contact support."), delegate: nil, cancelButtonTitle: LocalizedString.OK)
                        alertView.show()
                    }
                }
            }
        }
    }
}