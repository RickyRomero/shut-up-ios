//
//  StylesheetUpdate.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/26/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit
import Foundation
import SafariServices

extension AppDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        _ = StylesheetUpdate(application, performFetchWithCompletionHandler: completionHandler, useEtag: true)
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        NSLog("Woken up.")
    }
}



class StylesheetUpdate {
    var completionHandler: (UIBackgroundFetchResult) -> (Void)

    // @escaping (DataResponse<String>) -> Void
    init(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void, useEtag: Bool)
    {
        print("Perform background refresh.")
        self.completionHandler = { completionHandler($0) }

        let sessionConfig = URLSessionConfiguration.ephemeral
        let version = UIApplication.versionBuild()
        let userDefaults = UserDefaults.standard
        let ETag: String? = userDefaults.string(forKey: "ETag")
        let stylesheetUrl = URL(string: "https://rickyromero.com/shutup/updates/shutup.css")!
        var additionalHeaders = [
            "User-Agent": "Shut Up Touch/\(version)",
            "Accept-Encoding": ""
        ]
        
        if ETag != nil && ETag != "" && useEtag {
            print("SENDING ETAG: \(ETag!)")
            additionalHeaders["If-None-Match"] = ETag!
        } else {
            print("NO ETAG!!!")
        }

        sessionConfig.timeoutIntervalForRequest = 5 // seconds
        sessionConfig.timeoutIntervalForRequest = 10 // seconds
        sessionConfig.allowsCellularAccess = true
        sessionConfig.httpAdditionalHeaders = additionalHeaders

        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: stylesheetUrl, completionHandler: finishAndStoreFetch(data:response:error:))

        sessionTask.resume()

        NSLog("Download begun.")
    }

    func finishAndStoreFetch(data: Data?, response: URLResponse?, error: Error?) {
        func failRequest() {
            print("Request failed.")
            self.completionHandler(.failed)
        }

        print("SESSION / DOWNLOADTASK / DIDFINISHDOWNLOADINGTOURL")
        guard error == nil else { return failRequest() }
        guard let response = response as? HTTPURLResponse else { return failRequest() }
        guard let data = data else { return failRequest() }

        if response.statusCode == 304 {
            print("RETURNING: NO DATA")
            self.completionHandler(.noData)
            return
        }

        guard response.statusCode == 200 else { return failRequest() }
        guard !data.isEmpty else { return failRequest() }
        guard response.mimeType == "text/css" else { return failRequest() }

        let userDefaults = UserDefaults.standard

        if let etag = response.allHeaderFields["Etag"] as? String {
            print(etag)
            userDefaults.set(etag, forKey: "ETag")
        } else {
            userDefaults.set("", forKey: "ETag")
        }

        print("Received \(data.count) bytes.")
        print("REQUEST OK")
        print("-----------------------")
        NSLog("%@", response.allHeaderFields)
        print("-----------------------")
        print(response.statusCode)

        if updateStoredCSSFile(data) {
            print("RETURNING: NEW DATA")
            self.completionHandler(.newData)
        } else {
            print("RETURNING: NO DATA")
            self.completionHandler(.noData)
        }
    }

    // Returns a boolean describing whether an update has occurred.
    func updateStoredCSSFile(_ data: Data) -> Bool {
        let cachePath = AppUtilities.sharedInstance.cachePath()
        let cssPath = NSString(string: cachePath).appendingPathComponent("shutup.css")

        let fileManager = FileManager.default
        
        print(cachePath)
        
        createCacheFolderIfNecessary()

        if fileManager.fileExists(atPath: cssPath)
        {
//            print(FileHash.sha512HashOfFileAtPath(cssPath))

            do
            {
                try fileManager.removeItem(atPath: cssPath)
            }
            catch
            {
                print(error)
                AppUtilities.sharedInstance.criticalError("CSS update failed.", message: "Shut Up could not delete its stale cached stylesheet. This error is unrecoverable.")
            }
        }

        fileManager.createFile(atPath: cssPath,
                                       contents: data,
                                       attributes: [FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue): FileProtectionType.completeUntilFirstUserAuthentication])

        BlocklistController.sharedInstance.readBlocklistCSS()

        // TODO: Check if the files actually match.
        return true
    }

}



func cssToSelector(_ css: String) -> String
{
    let strippedCSS = stripCSS(css)

    let displayNoneRegex = try! NSRegularExpression(pattern: "display:\\s*none", options: NSRegularExpression.Options.caseInsensitive)
    let declarationBlocks = strippedCSS.components(separatedBy: "}")
    let selectorWhitespaceRegex = try! NSRegularExpression(pattern: "^\\s+|\\s+$", options: NSRegularExpression.Options.dotMatchesLineSeparators)
    let concatString = ", "

    var declarationBlock: String!
    var displayNoneCount = 0
    var selector = ""
    var fullSelector = [String]()
    var i: Int = 0

    while (i < declarationBlocks.count)
    {
        declarationBlock = declarationBlocks[i];
        
        displayNoneCount = displayNoneRegex.numberOfMatches(in: declarationBlock,
            options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, declarationBlock.count))
        
        if (displayNoneCount != 0)
        {
            selector = declarationBlock.components(separatedBy: "{")[0]
            selector = selectorWhitespaceRegex.stringByReplacingMatches(in: selector,
                options: NSRegularExpression.MatchingOptions(),
                range: NSMakeRange(0, selector.count),
                withTemplate: "")
            
            fullSelector += [selector]
        }

        i += 1;
    }
    
    print("---------------------------------")

    return fullSelector.joined(separator: concatString)
}

func stripCSS(_ css: String) -> String
{
    let cleanupPatterns = [
        ["/\\*.+?\\*/",     ""],     // Comments
        ["^\\s+",           ""],     // Leading whitespace
        [",\\s+",           ", "]    // Selector whitespace
    ];
    var i: Int = 0
    
    var strippedCSS: String = css
    var cleanupPattern: String!
    var replacementTemplate: String!
    var cleanupRegex: NSRegularExpression!
    while (i < cleanupPatterns.count)
    {
        cleanupPattern = cleanupPatterns[i][0]
        replacementTemplate = cleanupPatterns[i][1]
        cleanupRegex = try! NSRegularExpression(pattern: cleanupPattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        strippedCSS = cleanupRegex.stringByReplacingMatches(in: strippedCSS,
            options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, strippedCSS.count),
            withTemplate: replacementTemplate)
        i += 1;
    }

    print(strippedCSS)

    return strippedCSS
}
