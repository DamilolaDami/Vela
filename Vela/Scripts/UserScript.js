//
//  UserScript.js
//  Vela
//
//  Created by damilola on 6/20/25.
//

// UserScript.js
(function() {
    if (window.getUserMediaIntercepted) return;
    window.getUserMediaIntercepted = true;

    console.log('🔊 Intercepting getUserMedia');

    const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);

    navigator.mediaDevices.getUserMedia = function(constraints) {
        return new Promise((resolve, reject) => {
            const callbackId = Date.now();
            window.webkit.messageHandlers.callbackHandler.postMessage({
                constraints: constraints,
                success: `resolve${callbackId}`,
                error: `reject${callbackId}`
            });

            // Store callbacks
            window[`resolve${callbackId}`] = resolve;
            window[`reject${callbackId}`] = reject;
        });
    };
})();
