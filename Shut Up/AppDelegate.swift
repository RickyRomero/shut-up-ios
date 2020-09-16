//
//  AppDelegate.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/25/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var quickAction: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initialSetup()

        UIApplication.shared.setMinimumBackgroundFetchInterval(Double(60 * 60 * 24))

        quickAction = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        quickAction = shortcutItem
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let pvc = window?.rootViewController as? PrimaryViewController else { return }
        guard let quickAction = quickAction else { return }
        self.quickAction = nil // Reset this just in case this is called twice

        // Dismiss any active view controller if applicable
        pvc.dismiss(animated: true) {
            pvc.handleQuickAction(quickAction.type)
        }
    }
}
