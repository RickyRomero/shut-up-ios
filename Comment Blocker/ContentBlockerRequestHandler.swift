//
//  ContentBlockerRequestHandler.swift
//  Comment Blocker
//
//  Created by Ricky Romero on 6/28/15.
//  See LICENSE.md for license information.
//

import UIKit
import MobileCoreServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    
    // There's a crasher somewhere in here...
    func beginRequest(with context: NSExtensionContext)
    {
        let sharedSupport = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rickyromero.shutup")!
        let blocklistLocation = NSString(string: sharedSupport.path).appendingPathComponent("blocklist.json")
        let blocklistURL = URL(fileURLWithPath: blocklistLocation)
        
        let attachment = NSItemProvider(contentsOf: blocklistURL)!
        
        let item = NSExtensionItem()
        item.attachments = [attachment]
        
        context.completeRequest(returningItems: [item], completionHandler: finishRequest);
    }
    
    func finishRequest(_ result: Bool)
    {
    }
    
}
