//
//  AppSetup.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/27/15.
//  See LICENSE.md for license information.
//

import UIKit
import Foundation

func initialSetup()
{
    let userDefaults = UserDefaults.standard
    let previousSetupPerformed: Bool? = userDefaults.bool(forKey: "FirstRun")
    print(previousSetupPerformed!)

    if previousSetupPerformed!
    {
        // Upgrade path.
        print("Initial setup already done.")
        performUpgradeIfNecessary()
    }
    else
    {
        // First time.
        print("Performing initial setup!")

        createCacheFolderIfNecessary()
        BlocklistController.sharedInstance.createDefaultWhitelist()

        userDefaults.set(true, forKey: "FirstRun")
        userDefaults.set(UIApplication.appBuild(), forKey: "BuildNumber")
        userDefaults.set("", forKey: "ETag")
    }

    userDefaults.synchronize()
}

@discardableResult
func performUpgradeIfNecessary() -> Bool
{
    let userDefaults = UserDefaults.standard
    let lastBuildRun:String? = userDefaults.string(forKey: "BuildNumber")
    let currentBuild = UIApplication.appBuild()
    
    print("Previous build was \(lastBuildRun!). Current build is \(currentBuild).")
    
    switch lastBuildRun!
    {
        case currentBuild: // Prevent upgrade from being performed.
            print("Version hasn't changed since previous run.")
            return false
        
        // Upgrade cases.
        case "323": fallthrough // Beta 1
        case "324": fallthrough // Beta 1
        case "325": fallthrough // Beta 1
        case "326": fallthrough // Beta 1
        case "328":             // Beta 1
            BlocklistController.sharedInstance.createDefaultWhitelist()
            fallthrough

        // No upgrade necessary.
        default:
            refreshCSSFromAppSource()
            print("No upgrade required for previous build.")
    }
    
    userDefaults.set(UIApplication.appBuild(), forKey: "BuildNumber")
    return false;
}

@discardableResult
func createCacheFolderIfNecessary() -> Bool
{
    // Create cache directory.
    let cachePath = AppUtilities.sharedInstance.cachePath()
    let fileManager = FileManager.default
    var folderCreated = false

    if !fileManager.fileExists(atPath: cachePath)
    {
        do
        {
            try fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: false, attributes: nil)
            folderCreated = true
            print("Cache folder created. Yay!")

            // Seed the initial content blocker.
            refreshCSSFromAppSource()
            BlocklistController.sharedInstance.readBlocklistCSS()
        }
        catch
        {
            AppUtilities.sharedInstance.criticalError("Initial setup failed.", message: "Shut Up failed to create a critical cache folder. This error is unrecoverable.")
        }
    }

    return folderCreated
}

func refreshCSSFromAppSource()
{
    print("REFRESHING CSS FROM APP BUNDLE")

    let fileManager = FileManager.default
    let cachePath = AppUtilities.sharedInstance.cachePath()
    let localCSS = Bundle.main.path(forResource: "shutup", ofType: "css")
    let cssPath = NSString(string: cachePath).appendingPathComponent("shutup.css")

    do
    {
        if (fileManager.fileExists(atPath: cssPath))
        {
            try fileManager.removeItem(atPath: cssPath)
        }

        try fileManager.copyItem(atPath: localCSS!, toPath: cssPath)
    }
    catch
    {
        print(error)
        AppUtilities.sharedInstance.criticalError("CSS update failed.", message: "Shut Up could not copy its stylesheet into the cache. This error is unrecoverable.")
    }
}
