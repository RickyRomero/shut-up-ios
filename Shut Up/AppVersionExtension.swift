//
//  AppVersionExtension.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/27/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit

extension UIApplication {
    class func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    class func appBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }
    
    class func versionBuild() -> String {
        let version = appVersion(), build = appBuild()
        
        return version == build ? "\(version)" : "\(version) (\(build))"
    }
}
