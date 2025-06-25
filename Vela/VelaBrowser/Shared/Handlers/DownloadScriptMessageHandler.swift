import SwiftUI
import WebKit

class DownloadScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var webView: CustomWKWebView?
    
    // Store pending download positions
    private var pendingDownloads: [CGPoint] = []
    private let pendingDownloadsQueue = DispatchQueue(label: "pendingDownloads", attributes: .concurrent)
    
    init(webView: CustomWKWebView) {
        self.webView = webView
        super.init()
        print("🔧 DownloadScriptMessageHandler initialized")
        
        // Listen for when downloads are actually added
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(downloadItemAdded),
            name: .downloadItemAdded,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // In your DownloadScriptMessageHandler class
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("📨 Message received from JavaScript: \(message.body)")
        
        guard let body = message.body as? [String: Any] else {
            print("❌ Message body is not a dictionary: \(message.body)")
            return
        }
        
        guard let type = body["type"] as? String else {
            print("❌ No type found in message body")
            return
        }
        
        print("🏷️ Message type: \(type)")
        
        // Handle test messages
        if type == "test" {
            if let testMessage = body["message"] as? String {
                print("✅ Test message received: \(testMessage)")
            }
            return
        }
        
        // Handle download click messages
        if type == "downloadClick" {
            print("📥 Download click message received")
            
            guard let positionData = body["position"] as? [String: Any] else {
                print("❌ No position data in download click message")
                return
            }
            
            // Get the original JavaScript coordinates for testing
            guard let viewportData = positionData["viewport"] as? [String: Any],
                  let jsX = viewportData["x"] as? Double,
                  let jsY = viewportData["y"] as? Double else {
                print("❌ Could not extract viewport position from message")
                return
            }
            
            // 🎯 ADD THE TEST HERE - BEFORE calculating the final position
            print("🧪 Testing all position approaches...")
          
            
            // Calculate the correct position in WebView coordinates
            let buttonPosition = calculateWebViewPosition(from: positionData)
            
            guard let position = buttonPosition else {
                print("❌ Could not calculate valid WebView position")
                return
            }
            
            print("📍 Final calculated position: \(position)")
            
            // Store the position for when the download actually starts
            pendingDownloadsQueue.async(flags: .barrier) {
                self.pendingDownloads.append(position)
                print("📌 Stored pending download position: \(position). Total pending: \(self.pendingDownloads.count)")
            }
            
            // Set a timeout to clean up stale pending downloads
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.cleanupStalePosition(position)
            }
            
        } else {
            print("❓ Unknown message type: \(type)")
        }
    }
    
    private func calculateWebViewPosition(from positionData: [String: Any]) -> CGPoint? {
        guard let webView = self.webView else {
            print("❌ WebView is nil")
            return nil
        }
        
        // Get the viewport position from JavaScript
        guard let viewportData = positionData["viewport"] as? [String: Any],
              let jsX = viewportData["x"] as? Double,
              let jsY = viewportData["y"] as? Double else {
            print("❌ Could not extract viewport position from message")
            return nil
        }
        
        print("📍 JavaScript viewport position: (\(jsX), \(jsY))")
        
        // Log WebView frame and bounds
        let webViewFrame = webView.frame
        let webViewBounds = webView.bounds
        print("🖼️ WebView frame: \(webViewFrame)")
        print("🖼️ WebView bounds: \(webViewBounds)")
        
        // Initialize screen position with a default value
        var jsPointInScreen: CGPoint = .zero
        
        // Debug: Log window and content view coordinates
        if let window = webView.window, let contentView = window.contentView {
            let windowFrame = window.frame
            let contentViewFrame = contentView.frame
            let webViewOriginInWindow = webView.convert(CGPoint.zero, to: nil)
            let jsPointInWindow = webView.convert(CGPoint(x: jsX, y: jsY), to: nil)
            // Adjust for window's bottom-left origin and WebView offset
            let contentViewHeight = contentViewFrame.height
            let webViewOffsetY = contentViewHeight - webViewBounds.height // e.g., 752.0 - 714.0 = 38.0
            let adjustedWindowY = contentViewHeight - jsPointInWindow.y - webViewOffsetY
            let adjustedWindowPoint = CGPoint(x: jsPointInWindow.x, y: adjustedWindowY)
            
            // Convert to screen coordinates
            let windowOriginInScreen = window.convertPoint(toScreen: CGPoint.zero)
            jsPointInScreen = CGPoint(
                x: jsPointInWindow.x + windowOriginInScreen.x,
                y: windowOriginInScreen.y + adjustedWindowY
            )
            
            print("🪟 Window frame: \(windowFrame)")
            print("🪟 Content view frame: \(contentViewFrame)")
            print("🪟 WebView origin in window coordinates: \(webViewOriginInWindow)")
            print("🪟 JS point in window coordinates (raw): \(jsPointInWindow)")
            print("🪟 JS point in window coordinates (adjusted): \(adjustedWindowPoint)")
            print("🖥️ JS point in screen coordinates: \(jsPointInScreen)")
            
            // Debug: Superview coordinates
            if let superview = webView.superview {
                let superviewFrame = superview.frame
                let webViewInSuperview = webView.convert(CGPoint.zero, to: superview)
                print("🖼️ WebView superview frame: \(superviewFrame)")
                print("🖼️ WebView origin in superview coordinates: \(webViewInSuperview)")
            }
        }
        
        // Use JavaScript coordinates directly for WebView (top-left origin, no scaling)
        let jsPoint = CGPoint(x: jsX, y: jsY)
        
        // Clamp to WebView bounds
        let clampedPosition = CGPoint(
            x: max(0, min(jsX, webViewBounds.width)),
            y: max(0, min(jsY, webViewBounds.height))
        )
        
        print("📍 Final chosen position: \(clampedPosition)")
        print("📏 Clamped using bounds: \(webViewBounds.width) x \(webViewBounds.height)")
        
        // Log NSView conversion for comparison (corrected)
        let nsViewConverted = webView.convert(jsPoint, to: nil)
        print("🧪 NSView converted (for comparison): \(nsViewConverted)")
        
        // Post notification with WebView and screen positions
        NotificationCenter.default.post(
            name: .downloadStarted,
            object: nil,
            userInfo: [
                "buttonPosition": clampedPosition,
                "screenPosition": jsPointInScreen
            ]
        )
        
        return clampedPosition
    }

    // MARK: - Debug Helper Methods

    // Add this method to help debug coordinate issues
    func debugCoordinateSystem() {
        guard let webView = self.webView else { return }
        
        let testScript = """
            (function() {
                // Create a temporary test element at known positions
                const testDiv = document.createElement('div');
                testDiv.style.position = 'fixed';
                testDiv.style.left = '100px';
                testDiv.style.top = '100px';
                testDiv.style.width = '10px';
                testDiv.style.height = '10px';
                testDiv.style.backgroundColor = 'red';
                testDiv.style.zIndex = '9999';
                testDiv.id = 'coordinate-test';
                
                document.body.appendChild(testDiv);
                
                const rect = testDiv.getBoundingClientRect();
                
                // Clean up
                document.body.removeChild(testDiv);
                
                return {
                    expectedPosition: { x: 100, y: 100 },
                    actualRect: {
                        left: rect.left,
                        top: rect.top,
                        right: rect.right,
                        bottom: rect.bottom
                    },
                    viewport: {
                        width: window.innerWidth,
                        height: window.innerHeight
                    },
                    scroll: {
                        x: window.scrollX,
                        y: window.scrollY
                    }
                };
            })();
        """
        
        webView.evaluateJavaScript(testScript) { result, error in
            if let data = result as? [String: Any] {
                print("🧪 Coordinate system debug data:")
                print("   Expected: (100, 100)")
                if let actualRect = data["actualRect"] as? [String: Any] {
                    print("   Actual rect: \(actualRect)")
                }
                if let viewport = data["viewport"] as? [String: Any] {
                    print("   Viewport: \(viewport)")
                }
            }
        }
    }

    // MARK: - Quick Test Method for Position Accuracy
    // Call this method to test which coordinate calculation works best


    
    @objc private func downloadItemAdded(_ notification: Notification) {
        print("📦 Download item was added - checking for pending positions")
        
        pendingDownloadsQueue.async(flags: .barrier) {
            guard !self.pendingDownloads.isEmpty else {
                print("⚠️ No pending download positions available")
                return
            }
            
            // Use FIFO - take the first pending download position
            let position = self.pendingDownloads.removeFirst()
            print("🎯 Using pending download position: \(position). Remaining: \(self.pendingDownloads.count)")
            
            // Get screen position from userInfo
            guard let userInfo = notification.userInfo,
                  let screenPosition = userInfo["screenPosition"] as? CGPoint else {
                print("❌ No screen position available in notification")
                return
            }
            
            // Trigger animation on main thread
            DispatchQueue.main.async {
                print("📢 Posting downloadStarted notification with position: \(position), screen: \(screenPosition)")
                NotificationCenter.default.post(
                    name: .downloadStarted,
                    object: nil,
                    userInfo: [
                        "buttonPosition": position,
                        "screenPosition": screenPosition
                    ]
                )
            }
        }
    }
    
    private func cleanupStalePosition(_ position: CGPoint) {
        pendingDownloadsQueue.async(flags: .barrier) {
            if let index = self.pendingDownloads.firstIndex(of: position) {
                self.pendingDownloads.remove(at: index)
                print("🧹 Cleaned up stale pending download position: \(position)")
            }
        }
    }
    
    // Debug method to test coordinate transformation
    func testCoordinateTransformation() {
        guard let webView = self.webView else { return }
        
        let testScript = """
            (function() {
                // Test coordinates at known positions
                const testPositions = [
                    { name: 'top-left', x: 0, y: 0 },
                    { name: 'top-right', x: window.innerWidth, y: 0 },
                    { name: 'center', x: window.innerWidth/2, y: window.innerHeight/2 },
                    { name: 'bottom-left', x: 0, y: window.innerHeight },
                    { name: 'bottom-right', x: window.innerWidth, y: window.innerHeight }
                ];
                
                const viewportInfo = {
                    width: window.innerWidth,
                    height: window.innerHeight,
                    scrollX: window.scrollX,
                    scrollY: window.scrollY,
                    devicePixelRatio: window.devicePixelRatio || 1
                };
                
                return {
                    testPositions: testPositions,
                    viewportInfo: viewportInfo
                };
            })();
        """
        
        webView.evaluateJavaScript(testScript) { [weak self] result, error in
            if let data = result as? [String: Any] {
                print("🧪 Coordinate test data: \(data)")
                // You can use this to test your coordinate transformation
            }
        }
    }
    
}

// Add this extension to make CGPoint Equatable for cleanup
extension CGPoint: Equatable {
    public static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return abs(lhs.x - rhs.x) < 1.0 && abs(lhs.y - rhs.y) < 1.0
    }
}
