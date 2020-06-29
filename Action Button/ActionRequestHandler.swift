//
//  ActionRequestHandler.swift
//  Action Button
//
//  Created by Ricky Romero on 6/28/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit
import MobileCoreServices
import SafariServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequest(with context: NSExtensionContext) {
        print("##### HOST APP HAS ISSUED REQUEST.")
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        print(context)

        var found = false
        
        // Find the item containing the results from the JavaScript preprocessing.
//        outer:
//            for item: AnyObject in context.inputItems {
//                print("item")
//                let extItem = item as! NSExtensionItem
//                if let attachments = extItem.attachments {
//                    print("attachment")
//                    for itemProvider: AnyObject in attachments {
//                        print("itemProvider")
//                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePropertyList)) {
//                            print("hasItemConformingToTypeIdentifier")
//                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypePropertyList), options: nil, completionHandler: { (item, error) in
//                                print("loadItemForTypeIdentifier")
//                                let dictionary = item as! [String: AnyObject]
//                                OperationQueue.main.addOperation {
//                                    print("addOperationWithBlock")
//                                    self.itemLoadCompletedWithPreprocessingResults(dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! [AnyHashable: Any])
//                                }
//                                found = true
//                            })
//                            if found {
//                                break outer
//                            }
//                        }
//                    }
//                }
//            }
    }
    
    func itemLoadCompletedWithPreprocessingResults(_ javaScriptPreprocessingResults: [AnyHashable: Any]) {
//        SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.rickyromero.shutup.blocker", completionHandler: completeLoad)
        print("##### PAGE JAVASCRIPT HAS SENT A MESSAGE.")
        // Here, do something, potentially asynchronously, with the preprocessing
        // results.
        
        // In this very simple example, the JavaScript will have passed us the
        // current background color style, if there is one. We will construct a
        // dictionary to send back with a desired new background color style.
        let bgColor: AnyObject? = javaScriptPreprocessingResults["currentBackgroundColor"] as AnyObject?
        if bgColor == nil ||  bgColor! as! String == "" {
            // No specific background color? Request setting the background to red.
            self.doneWithResults(["newBackgroundColor": "red"])
        } else {
            // Specific background color is set? Request replacing it with green.
            self.doneWithResults(["newBackgroundColor": "green"])
        }
    }

    func completeLoad(_ error: NSError?)
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


    func doneWithResults(_ resultsForJavaScriptFinalizeArg: [AnyHashable: Any]?) {
        print("##### RESPONDING TO MESSAGE.")
//        print(resultsForJavaScriptFinalizeArg)
        if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
            // Construct an NSExtensionItem of the appropriate type to return our
            // results dictionary in.
            
            // These will be used as the arguments to the JavaScript finalize()
            // method.
            
            let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
            print(resultsDictionary)

            let resultsProvider = NSItemProvider(item: resultsDictionary as NSSecureCoding?, typeIdentifier: String(kUTTypePropertyList))
            print(resultsProvider)

            let resultsItem = NSExtensionItem()
            resultsItem.attachments = [resultsProvider]
            print(resultsItem)
            
//            print(self.extensionContext)
            // Signal that we're complete, returning our results.
            print("##### SENDING MESSAGE BACK TO JAVASCRIPT.")
            self.extensionContext!.completeRequest(returningItems: [resultsItem], completionHandler: self.complete)
        } else {
            // We still need to signal that we're done even if we have nothing to
            // pass back.
            print("##### JAVASCRIPT IS NOT WORTHY OF OUR ATTENTION.")
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: self.complete)
        }
        
        // Don't hold on to this after we finished with it.
        print("DANGER!!!! SETTING EXTENSION CONTEXT TO NIL!!!!!!")
//        self.extensionContext = nil
    }

    func complete(_ expired: Bool)
    {
        print("##### Done.  Expired?: \(expired)")
    }
}
