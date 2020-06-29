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
import Alamofire

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
    var sessionManager: SessionManager?

    // @escaping (DataResponse<String>) -> Void
    init(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void, useEtag: Bool)
    {
        self.completionHandler = { completionHandler($0) }

        print("Perform background refresh.")
        
        let version = UIApplication.versionBuild()
        
        let userDefaults = UserDefaults.standard
        let ETag: String? = userDefaults.string(forKey: "ETag")
        
        var additionalHeaders = ["User-Agent": "Shut Up Touch/\(version)"]
        
        if (ETag != nil && ETag != "" && useEtag)
        {
            print("SENDING ETAG: \(ETag!)")
            additionalHeaders["If-None-Match"] = ETag!
        }
        else
        {
            print("NO ETAG!!!")
        }
        
        additionalHeaders["Accept-Encoding"] = ""
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.rickyromero.shutup.stylesheet-update")
        sessionConfiguration.requestCachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
        sessionConfiguration.isDiscretionary = true
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.httpMaximumConnectionsPerHost = 1
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders

        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 10.0

        self.sessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        self.sessionManager?.request("https://rickyromero.com/shutup/updates/shutup.css").responseString(queue: nil, encoding: nil, completionHandler: self.finishAndStoreFetch)

        NSLog("Download begun.")
    }

    func finishAndStoreFetch(response: DataResponse<String>)
    {
        print("SESSION / DOWNLOADTASK / DIDFINISHDOWNLOADINGTOURL")

        var success = response.result.isSuccess
        if (success == false)
        {
            print("Request failed.")
            self.callback(UIBackgroundFetchResult.failed)
            return
        }

        let httpResponse = response.response!
        let userDefaults = UserDefaults.standard
        let responseLength = (response.data?.count)!

        // Account for header fields not being case-insensitive
        var ETag = httpResponse.allHeaderFields["ETag"]
        if (ETag == nil) { ETag = httpResponse.allHeaderFields["Etag"] }
        if (ETag == nil) { ETag = httpResponse.allHeaderFields["etag"] }

        print("Received \(String(describing: responseLength)) bytes.")

        if ETag != nil
        {
            print(ETag!)
            userDefaults.set(ETag!, forKey: "ETag")
        }
        else
        {
            userDefaults.set("", forKey: "ETag")
        }

        userDefaults.synchronize()

        switch httpResponse.statusCode
        {
            case 200:
                print("REQUEST OK")

                print("-----------------------")
                NSLog("%@", httpResponse.allHeaderFields)
                print("-----------------------")
                
                if httpResponse.mimeType != "text/css"
                {
                    success = false
                    print("ERROR: WRONG MIME TYPE")
                }

                if responseLength > 0
                {
                    print("Downloaded: \(String(describing: responseLength)).")
                }
                else
                {
                    success = false
                    print("ERROR: NO BYTES RECEIVED")
                }

                print(httpResponse.statusCode)
            case 304:
                print("RETURNING: NO DATA")
                self.callback(UIBackgroundFetchResult.noData)
                return
            default:
                success = false
                print("ERROR: BAD RESPONSE CODE")
        }


        if (success)
        {
            if updateStoredCSSFile(response.data!)
            {
                print("RETURNING: NEW DATA")

                self.callback(UIBackgroundFetchResult.newData)
            }
            else
            {
                print("RETURNING: NO DATA")
                self.callback(UIBackgroundFetchResult.noData)
            }
        }
        else
        {
            print("RETURNING: FAILED")
            self.callback(UIBackgroundFetchResult.failed)
        }
    }

    func callback(_ result: UIBackgroundFetchResult)
    {
        self.completionHandler(result)
        self.sessionManager!.session.finishTasksAndInvalidate()
    }

    // Returns a boolean describing whether an update has occurred.
    func updateStoredCSSFile(_ data: Data) -> Bool
    {
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
