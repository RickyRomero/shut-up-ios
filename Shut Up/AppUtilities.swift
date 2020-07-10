//
//  AppUtilities.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/27/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit
import Foundation

class AppUtilities : NSObject {
    static let sharedInstance = AppUtilities()
    var error: Dictionary<String, String>
    var interfaceAvailable = false
    var mainTintColor = UIColor(red: 235 / 255, green: 0, blue: 66 / 255, alpha: 1.0)
    var betaAcknowledged = false

    override init()
    {
        self.error = [:]
    }

    func cachePath() -> String
    {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let userCacheDirectory: String = paths[0]
        let appCacheDirectory: NSString = NSString(string: userCacheDirectory)
        
        return appCacheDirectory.appendingPathComponent("com.rickyromero.shutup") as String
    }

    func criticalError(_ title: String, message: String)
    {
        // TODO: Handle multiple errors.
        // TODO: Store errors in case app is killed in background.
        var canPresentError = (UIApplication.shared.applicationState == UIApplication.State.active)
        canPresentError = (canPresentError && self.interfaceAvailable)

        // Could be called before we are able to present a dialog box,
        // so we need to store the error for when we are able to display it.
        self.error["title"] = title
        self.error["message"] = message
        print(UIApplication.shared.applicationState == UIApplication.State.active)

        if (canPresentError)
        {
            self.presentCriticalErrorsIfNecessary()
        }
    }

    func presentCriticalErrorsIfNecessary()
    {
        // TODO: Handle when the app is backgrounded and reopened.

        if (self.error["title"] != nil && self.interfaceAvailable)
        {
            let currentViewController = UIApplication.shared.windows[0].rootViewController
            
            let alert = UIAlertController(title: self.error["title"], message: self.error["message"], preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Quit", style: UIAlertAction.Style.default, handler: self.die))
            currentViewController!.present(alert, animated: true, completion: nil)
        }
    }

    func die(_ action: UIAlertAction)
    {
        exit(EXIT_FAILURE)
    }
}

func print(_ value: Any)
{
    #if DEBUG
        Swift.print(value)
    #endif
}

