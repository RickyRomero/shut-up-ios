//
//  Action.js
//  Action Button
//
//  Created by Ricky Romero on 6/28/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        // Here, you can run code that modifies the document and/or prepares
        // things to pass to your action's native code.
        
        // We will not modify anything, but will pass the body's background
        // style to the native code.

        var background = window.getComputedStyle(document.documentElement)["background-color"];
        arguments.completionFunction({ "currentBackgroundColor": background })
    },
    
    finalize: function(arguments) {
        document.documentElement.innerHTML="fuck you";
        // This method is run after the native code completes.
        
        // We'll see if the native code has passed us a new background style,
        // and set it on the body.
        
        var newBackgroundColor = arguments["newBackgroundColor"]
        if (newBackgroundColor) {
            // We'll set document.body.style.background, to override any
            // existing background.
            document.body.style.background = newBackgroundColor
        } else {
            // If nothing's been returned to us, we'll set the background to
            // blue.
            document.body.style.background= "blue"
        }
    }
    
};
    
var ExtensionPreprocessingJS = new Action
