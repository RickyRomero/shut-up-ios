//
//  BlocklistController.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/10/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import Foundation
import SafariServices

class BlocklistController: NSObject {

    static let sharedInstance = BlocklistController()

    let sharedSupport = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rickyromero.shutup")!
    var whitelistPath = ""

    var whitelistReady = false
    var whitelist = [String]()
    var whitelistWithWildcards = [String]()

    var selectorReady = false
    var selector = ""

    override init()
    {
        super.init()
        self.whitelistPath = NSString(string: self.sharedSupport.path).appendingPathComponent("domain-whitelist.json")
    }

    func createDefaultWhitelist()
    {
        self.whitelist = [
            "dribbble.com",
            "facebook.com",
            "github.com",
            "reddit.com",
            "stackoverflow.com",
            "swipe-left-to-delete.me"
        ];

        self.writeWhitelist()
    }

    func addDomainToWhitelist(_ domain: String) -> Int
    {
        let lowercaseDomain = domain.lowercased()

        if (!self.domainExistsInWhitelist(lowercaseDomain))
        {
            self.whitelist.append(lowercaseDomain)
            self.whitelist.sort { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
            self.writeWhitelist()
            return self.whitelist.index(of: lowercaseDomain)!
        }
        else
        {
            return -1
        }
    }

    @discardableResult
    func removeDomainFromWhitelist(_ domain: String) -> Bool
    {
        if (self.domainExistsInWhitelist(domain))
        {
            self.whitelist.remove(at: self.whitelist.index(of: domain)!)
            self.writeWhitelist()
            return true
        }
        else
        {
            return false
        }
    }

    func domainExistsInWhitelist(_ domain: String) -> Bool
    {
        return (self.whitelist.index(of: domain) != nil)
    }

    func readWhitelist()
    {
        self.whitelist.removeAll()
        self.whitelistWithWildcards.removeAll()

        do
        {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: whitelistPath), options: NSData.ReadingOptions.mappedIfSafe)
            let jsonResult = try (JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray) as Array

            print("READ WHITELIST. CONTENTS:")
            print(jsonResult)
            for domain in jsonResult
            {
                let str:String = (domain as! String)
                self.whitelist.append(String(str.suffix(str.count - 1)))
                self.whitelistWithWildcards.append(str)
            }

            self.whitelistReady = true
        }
        catch
        {
            print("Couldn't read whitelist.")
            self.createDefaultWhitelist()
        }
    }

    func writeWhitelist()
    {
        print(whitelistPath)

        self.whitelistWithWildcards.removeAll()

        for domain in self.whitelist
        {
            self.whitelistWithWildcards.append("*" + domain)
        }

        print(self.whitelist)
        print(self.whitelistWithWildcards)

        do
        {
            let jsonData = try JSONSerialization.data(withJSONObject: self.whitelistWithWildcards, options: JSONSerialization.WritingOptions())
            FileManager.default.createFile(atPath: whitelistPath,
                contents: jsonData,
                attributes: [FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue): FileProtectionType.completeUntilFirstUserAuthentication])

            self.whitelistReady = true
            self.updateBlocklist()
        }
        catch
        {
            print(error)
        }
    }

    func readBlocklistCSS()
    {
        var fileContents:String = ""
        
        let cachePath = AppUtilities.sharedInstance.cachePath()
        let cssPath = NSString(string: cachePath).appendingPathComponent("shutup.css")

        do
        {
            fileContents = try String(contentsOfFile: cssPath, encoding: String.Encoding.utf8)
        }
        catch
        {
            // Cache missing? Cache is first thing to go if the device runs out of storage.
            // This is surprisingly common. Hm.
            print("Cache missing. Refreshing from app bundle...")
            createCacheFolderIfNecessary()
            refreshCSSFromAppSource()

            fileContents = try! String(contentsOfFile: cssPath, encoding: String.Encoding.utf8)
        }

        self.updateSelector(cssToSelector(fileContents))
    }

    @discardableResult
    func updateSelector(_ selector: String) -> Bool
    {
        if (selector.count > 0)
        {
            self.selector = selector
            self.selectorReady = true
            self.updateBlocklist()
        }
        else
        {
            return false
        }

        // TODO: Return false on failure.
        return true
    }

    func updateBlocklist() {
        if (!self.whitelistReady || !self.selectorReady)
        {
            return
        }

        var blockList = [[String:[String:Any]]]()

        print("UPDATING MASTER BLOCKLIST JSON.")
        let blocklistLocation = NSString(string: sharedSupport.path).appendingPathComponent("blocklist.json")
        print(blocklistLocation)

        let selectorList = self.selector.components(separatedBy: ",")
        for selector in selectorList
        {
            let trimmedSelector = selector.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            blockList.append([
                "action": [
                    "type": "css-display-none",
                    "selector": trimmedSelector,
                ],
                "trigger": [
                    "url-filter": ".*",
                    "unless-domain": self.whitelistWithWildcards
                ]
            ])
        }

        do
        {
            let jsonData = try JSONSerialization.data(withJSONObject: blockList, options: JSONSerialization.WritingOptions())
            FileManager.default.createFile(atPath: blocklistLocation,
                contents: jsonData,
                attributes: [FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue): FileProtectionType.completeUntilFirstUserAuthentication])

            SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.rickyromero.shutup.blocker", completionHandler: completeLoad)
        }
        catch
        {
            print(error)
        }
    }

    func completeLoad(error: Error?) -> Void
    {
        if (error != nil)
        {
            print(error!)
        }
        else
        {
            print("success!!!")
        }
    }
}
