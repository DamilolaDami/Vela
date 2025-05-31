import Foundation
import Combine
import WebKit

class Tab: Identifiable, Equatable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var url: URL?
    @Published var favicon: Data?
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isPlayingAudio: Bool = false
    var spaceId: UUID?
    let createdAt: Date
    @Published var lastAccessedAt: Date
    @Published var isPinned: Bool = false
    @Published var position: Int = 0
    @Published var scrollPosition: Double = 0
    var webView: WKWebView?
    private var cancellables = Set<AnyCancellable>()
    private var webViewObservers: [NSKeyValueObservation] = []
    private var audioCheckTimer: Timer?
    private var audioMessageHandler: AudioMessageHandler?
    private var navigationDelegate: TabNavigationDelegate?
    private var lastKnownURL: URL?
    
    // New properties for enhanced audio detection
    private var mediaPlaybackObserver: NSKeyValueObservation?
    private var hasMediaObserver: NSKeyValueObservation?
    
    init(
        id: UUID = UUID(),
        title: String = "New Tab",
        url: URL? = nil,
        favicon: Data? = nil,
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        spaceId: UUID? = nil,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        isPinned: Bool = false,
        position: Int = 0
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.favicon = favicon
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.spaceId = spaceId
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.isPinned = isPinned
        self.position = position
        
        setupFaviconObserver()
    }
    
    func reloadFavicon() {
        if let url = self.url {
            loadFavicon(for: url)
        }
    }
    
    private func setupFaviconObserver() {
        $url
            .sink { [weak self] url in
                guard let self = self, let url = url else { return }
                self.loadFavicon(for: url)
            }
            .store(in: &cancellables)
    }
    
    private func loadFavicon(for url: URL) {
        // Reset favicon
        self.favicon = nil
        
        guard let webView = webView else { return }
        
        let waitForLoadJS = """
        new Promise(resolve => {
            if (document.readyState === 'complete') {
                resolve();
            } else {
                window.addEventListener('load', resolve);
            }
        });
        """
        
        webView.evaluateJavaScript(waitForLoadJS) { [weak self] (_, _) in
            guard let self = self else { return }
            let faviconJS = """
            (function() {
                let link = document.querySelector('link[rel~="icon"]');
                return link ? link.href : null;
            })();
            """
            
            webView.evaluateJavaScript(faviconJS) { [weak self] (result, error) in
                guard let self = self else { return }
                
                if let faviconURLString = result as? String, let faviconURL = URL(string: faviconURLString) {
                    self.fetchFavicon(from: faviconURL)
                } else {
                    let faviconURL = url.deletingLastPathComponent().appendingPathComponent("favicon.ico")
                    self.fetchFavicon(from: faviconURL)
                }
            }
        }
    }
    
    private func fetchFavicon(from url: URL) {
        URLSession.shared.dataTaskPublisher(for: url)
            .map { Data($0.data) }
            .catch { _ in Just(Data()) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard !data.isEmpty else { return }
                self?.favicon = data
            }
            .store(in: &cancellables)
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }
    
    func setWebView(_ webView: WKWebView) {
        // Clean up old webView first
        if let oldWebView = self.webView {
            cleanupWebView(oldWebView)
        }
        
        self.webView = webView
        isPlayingAudio = false
        
        // Setup navigation delegate
        navigationDelegate = TabNavigationDelegate(tab: self)
        webView.navigationDelegate = navigationDelegate
        
        // Setup message handler for JavaScript communication
        setupAudioMessageHandler(webView)
        
        // Setup observers for WebView properties
        setupWebViewObservers()
        
        // Setup native media observers
        setupNativeMediaObservers()
        
        // Start JavaScript-based audio checking
        startAudioCheckTimer()
        
        print("🔧 WebView setup complete for: \(title)")
    }
    
    // MARK: - Native Media Observers
    private func setupNativeMediaObservers() {
//        guard let webView = webView else { return }
//        
//        // Clean up existing observers
//        mediaPlaybackObserver?.invalidate()
//        hasMediaObserver?.invalidate()
//        
//        // Observe hasOnlySecureContent (can indicate media activity)
//        if #available(macOS 12.0, *) {
//            hasMediaObserver = webView.observe(\.hasOnlySecureContent, options: [.new, .old]) { [weak self] webView, change in
//                DispatchQueue.main.async {
//                    self?.checkMediaActivity()
//                }
//            }
//        }
//        
//        print("🔧 Native media observers setup for: \(title)")
    }
    
    private func checkMediaActivity() {
        // This is a fallback method that checks for various indicators
        guard let webView = webView else { return }
        
        // Check if the page might be playing media by examining the DOM
        let mediaCheckJS = """
        (function() {
            let mediaCount = 0;
            let playingCount = 0;
            
            // Check audio elements
            document.querySelectorAll('audio').forEach(audio => {
                mediaCount++;
                if (!audio.paused && audio.currentTime > 0) {
                    playingCount++;
                }
            });
            
            // Check video elements
            document.querySelectorAll('video').forEach(video => {
                mediaCount++;
                if (!video.paused && video.currentTime > 0) {
                    playingCount++;
                }
            });
            
            return {
                totalMedia: mediaCount,
                playing: playingCount,
                hasActiveMedia: playingCount > 0
            };
        })();
        """
        
        webView.evaluateJavaScript(mediaCheckJS) { [weak self] result, error in
            guard let self = self,
                  let resultDict = result as? [String: Any],
                  let hasActiveMedia = resultDict["hasActiveMedia"] as? Bool else { return }
            
            DispatchQueue.main.async {
                if self.isPlayingAudio != hasActiveMedia {
                    self.isPlayingAudio = hasActiveMedia
                    let playing = resultDict["playing"] as? Int ?? 0
                    print("🔊 Native media check: \(hasActiveMedia) (\(playing) playing)")
                }
            }
        }
    }
    
    private func setupAudioMessageHandler(_ webView: WKWebView) {
        let contentController = webView.configuration.userContentController
        
        // Remove existing handler if any
        contentController.removeScriptMessageHandler(forName: "audioStateChanged")
        
        // Create new handler
        audioMessageHandler = AudioMessageHandler(tab: self)
        contentController.add(audioMessageHandler!, name: "audioStateChanged")
        
        print("🔧 Audio message handler setup for tab: \(title)")
    }
    
    // MARK: - Enhanced JavaScript Audio Detection
     func installEnhancedAudioDetection() {
        guard let webView = webView else { return }
        
        print("🔧 Installing enhanced audio detection for: \(title)")
        
        let enhancedAudioJS = """
        (function() {
            if (window.tabAudioDetectorInstalled) {
                return { success: true, message: 'Already installed' };
            }
            
            console.log('🔊 Installing enhanced audio detector');
            
            let currentAudioState = false;
            let checkInterval;
            let observers = [];
            
            function reportAudioState(isPlaying, details = '') {
                if (isPlaying !== currentAudioState) {
                    currentAudioState = isPlaying;
                    console.log('🔊 Audio state changed:', isPlaying, details);
                    
                    try {
                        if (window.webkit?.messageHandlers?.audioStateChanged) {
                            window.webkit.messageHandlers.audioStateChanged.postMessage({
                                isPlaying: isPlaying,
                                details: details,
                                url: window.location.href,
                                timestamp: Date.now()
                            });
                        }
                    } catch (error) {
                        console.log('🔊 Failed to send message:', error);
                    }
                }
            }
            
            function checkAllMedia() {
                let hasPlayingMedia = false;
                let details = [];
                
                try {
                    // Check HTML5 audio elements
                    const audioElements = document.querySelectorAll('audio');
                    audioElements.forEach((audio, index) => {
                        const isPlaying = !audio.paused && 
                                        audio.currentTime > 0 && 
                                        !audio.muted && 
                                        audio.volume > 0;
                        if (isPlaying) {
                            hasPlayingMedia = true;
                            details.push(`audio[${index}]`);
                        }
                    });
                    
                    // Check HTML5 video elements
                    const videoElements = document.querySelectorAll('video');
                    videoElements.forEach((video, index) => {
                        const isPlaying = !video.paused && 
                                        video.currentTime > 0 && 
                                        !video.muted && 
                                        video.volume > 0;
                        if (isPlaying) {
                            hasPlayingMedia = true;
                            details.push(`video[${index}]`);
                        }
                    });
                    
                    // Enhanced YouTube detection
                    if (window.location.hostname.includes('youtube.com')) {
                        // Method 1: Check main video element
                        const ytVideo = document.querySelector('video.html5-main-video');
                        if (ytVideo && !ytVideo.paused && ytVideo.currentTime > 0 && !ytVideo.muted) {
                            hasPlayingMedia = true;
                            details.push('youtube-main');
                        }
                        
                        // Method 2: Check player state via UI indicators
                        const playButton = document.querySelector('.ytp-play-button');
                        if (playButton) {
                            const isPaused = playButton.getAttribute('aria-label')?.toLowerCase().includes('play') ||
                                           playButton.getAttribute('title')?.toLowerCase().includes('play');
                            
                            const muteButton = document.querySelector('.ytp-mute-button');
                            const isMuted = muteButton?.classList.contains('ytp-muted') ||
                                          muteButton?.getAttribute('aria-label')?.toLowerCase().includes('unmute');
                            
                            if (!isPaused && !isMuted) {
                                hasPlayingMedia = true;
                                details.push('youtube-ui');
                            }
                        }
                        
                        // Method 3: Check for YouTube's internal player API
                        if (window.YT?.get) {
                            try {
                                const player = window.YT.get('movie_player');
                                if (player?.getPlayerState && player?.isMuted) {
                                    const state = player.getPlayerState();
                                    const muted = player.isMuted();
                                    if (state === 1 && !muted) { // 1 = YT.PlayerState.PLAYING
                                        hasPlayingMedia = true;
                                        details.push('youtube-api');
                                    }
                                }
                            } catch (e) {
                                console.log('YT API check failed:', e);
                            }
                        }
                    }
                    
                    // Spotify Web Player detection
                    if (window.location.hostname.includes('spotify.com')) {
                        // Check for Spotify's play button state
                        const playButton = document.querySelector('[data-testid="control-button-playpause"]');
                        if (playButton) {
                            const isPaused = playButton.getAttribute('aria-label')?.toLowerCase().includes('play');
                            if (!isPaused) {
                                hasPlayingMedia = true;
                                details.push('spotify-ui');
                            }
                        }
                        
                        // Alternative Spotify detection
                        const nowPlayingBar = document.querySelector('[data-testid="now-playing-widget"]');
                        const progressBar = document.querySelector('[data-testid="progress-bar"]');
                        if (nowPlayingBar && progressBar) {
                            // If there's content in the now playing bar, likely playing
                            const trackInfo = nowPlayingBar.querySelector('[data-testid="context-item-info-title"]');
                            if (trackInfo && trackInfo.textContent?.trim()) {
                                hasPlayingMedia = true;
                                details.push('spotify-nowplaying');
                            }
                        }
                    }
                    
                    // Generic Web Audio API detection (experimental)
                    if (window.AudioContext && window.webkitAudioContext) {
                        // This is tricky as we can't easily detect all audio contexts
                        // but we can check if any have been created recently
                    }
                    
                } catch (error) {
                    console.error('Error in media check:', error);
                }
                
                reportAudioState(hasPlayingMedia, details.join(', ') || 'none');
                return hasPlayingMedia;
            }
            
            function setupEventListeners() {
                // Media element events
                const mediaElements = document.querySelectorAll('audio, video');
                const events = ['play', 'pause', 'ended', 'volumechange', 'loadstart'];
                
                mediaElements.forEach(element => {
                    events.forEach(eventName => {
                        element.addEventListener(eventName, () => {
                            setTimeout(checkAllMedia, 100);
                        }, { passive: true });
                    });
                });
                
                // YouTube specific events
                if (window.location.hostname.includes('youtube.com')) {
                    // Monitor clicks on player controls
                    document.addEventListener('click', (e) => {
                        if (e.target.closest('.ytp-play-button, .ytp-mute-button, .ytp-volume-slider')) {
                            setTimeout(checkAllMedia, 300);
                        }
                    }, { passive: true, capture: true });
                    
                    // Monitor keyboard shortcuts
                    document.addEventListener('keydown', (e) => {
                        if (!e.target.matches('input, textarea, [contenteditable]')) {
                            const key = e.code || e.key;
                            if (['Space', 'KeyK', 'KeyM', 'ArrowLeft', 'ArrowRight'].includes(key)) {
                                setTimeout(checkAllMedia, 300);
                            }
                        }
                    }, { passive: true });
                }
                
                // Spotify specific events
                if (window.location.hostname.includes('spotify.com')) {
                    document.addEventListener('click', (e) => {
                        if (e.target.closest('[data-testid="control-button-playpause"], [data-testid="volume-bar"]')) {
                            setTimeout(checkAllMedia, 300);
                        }
                    }, { passive: true, capture: true });
                }
            }
            
            // DOM mutation observer for dynamically added media
            const observer = new MutationObserver((mutations) => {
                let shouldCheck = false;
                mutations.forEach(mutation => {
                    if (mutation.addedNodes.length > 0) {
                        mutation.addedNodes.forEach(node => {
                            if (node.nodeType === 1) { // Element node
                                if (node.matches('audio, video') || 
                                    node.querySelector('audio, video')) {
                                    shouldCheck = true;
                                }
                            }
                        });
                    }
                });
                
                if (shouldCheck) {
                    setTimeout(() => {
                        setupEventListeners();
                        checkAllMedia();
                    }, 200);
                }
            });
            
            observer.observe(document.body || document.documentElement, {
                childList: true,
                subtree: true
            });
            observers.push(observer);
            
            // Setup initial event listeners
            setupEventListeners();
            
            // Periodic fallback check
            checkInterval = setInterval(checkAllMedia, 3000);
            
            // Initial check after a brief delay
            setTimeout(checkAllMedia, 1000);
            
            // Mark as installed
            window.tabAudioDetectorInstalled = true;
            window.tabAudioCheckInterval = checkInterval;
            window.tabAudioObservers = observers;
            
            console.log('✅ Enhanced audio detector installed');
            return { success: true, message: 'Enhanced audio detector installed' };
        })();
        """
        
        webView.evaluateJavaScript(enhancedAudioJS) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Enhanced audio detection installation failed: \(error.localizedDescription)")
                } else {
                    print("✅ Enhanced audio detection installed for \(self?.title ?? "unknown")")
                }
            }
        }
    }
    
    // MARK: - Timer-based Audio Checking
    private func startAudioCheckTimer() {
        audioCheckTimer?.invalidate()
        audioCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkMediaActivity()
        }
        print("⏰ Audio check timer started for: \(title)")
    }
    
    private func stopAudioCheckTimer() {
        audioCheckTimer?.invalidate()
        audioCheckTimer = nil
        print("⏰ Audio check timer stopped for: \(title)")
    }
    
    // MARK: - WebView Observers
    private func setupWebViewObservers() {
        guard let webView = webView else { return }
        
        webViewObservers.forEach { $0.invalidate() }
        webViewObservers.removeAll()
        
        // Observe URL changes
        webViewObservers.append(
            webView.observe(\.url, options: [.new]) { [weak self] webView, change in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let newURL = webView.url
                    
                    if self.lastKnownURL != newURL {
                        self.url = newURL
                        self.lastKnownURL = newURL
                        self.isPlayingAudio = false
                        
                        print("🔄 URL changed to: \(newURL?.absoluteString ?? "nil")")
                        
                        // Install enhanced detection after page loads
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.installEnhancedAudioDetection()
                        }
                    }
                }
            }
        )
        
        // Observe loading state
        webViewObservers.append(
            webView.observe(\.isLoading, options: [.new]) { [weak self] webView, change in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = webView.isLoading
                    
                    if !webView.isLoading {
                        // Page finished loading, install detection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.installEnhancedAudioDetection()
                        }
                    }
                }
            }
        )
        
        // Observe title changes
        webViewObservers.append(
            webView.observe(\.title, options: [.new]) { [weak self] webView, change in
                DispatchQueue.main.async {
                    if let title = webView.title, !title.isEmpty {
                        self?.title = title
                    }
                }
            }
        )
    }
    
    // MARK: - Message Handling
    func handleAudioStateMessage(_ message: [String: Any]) {
        guard let isPlaying = message["isPlaying"] as? Bool else { return }
        
        DispatchQueue.main.async {
            let details = message["details"] as? String ?? "unknown"
            
            if self.isPlayingAudio != isPlaying {
                self.isPlayingAudio = isPlaying
                print("📨 Audio state from JS: \(isPlaying) (\(details))")
            }
        }
    }
    
    // MARK: - Public Methods
    func checkAudioPlayback() {
        print("🔍 Manual audio check requested for: \(title)")
        checkMediaActivity()
        
        // Also try to reinstall the JavaScript detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.installEnhancedAudioDetection()
        }
    }
    
    func reinstallAudioDetection() {
        print("🔄 Reinstalling audio detection for: \(title)")
        if let webView = self.webView {
            setupAudioMessageHandler(webView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.installEnhancedAudioDetection()
            }
        }
    }
    
    // MARK: - Cleanup
    private func cleanupWebView(_ webView: WKWebView) {
        webViewObservers.forEach { $0.invalidate() }
        webViewObservers.removeAll()
        
        mediaPlaybackObserver?.invalidate()
        hasMediaObserver?.invalidate()
        mediaPlaybackObserver = nil
        hasMediaObserver = nil
        
        // Clean up JavaScript
        let cleanupJS = """
        if (window.tabAudioCheckInterval) {
            clearInterval(window.tabAudioCheckInterval);
            window.tabAudioCheckInterval = null;
        }
        if (window.tabAudioObservers) {
            window.tabAudioObservers.forEach(observer => observer.disconnect());
            window.tabAudioObservers = null;
        }
        window.tabAudioDetectorInstalled = false;
        """
        
        webView.evaluateJavaScript(cleanupJS) { _, _ in }
        
        let contentController = webView.configuration.userContentController
        contentController.removeScriptMessageHandler(forName: "audioStateChanged")
        
        audioMessageHandler = nil
        navigationDelegate = nil
        stopAudioCheckTimer()
    }
    
    deinit {
        if let webView = self.webView {
            cleanupWebView(webView)
        }
        print("🗑️ Tab deinit: \(title)")
    }
}

// MARK: - Message Handler
class AudioMessageHandler: NSObject, WKScriptMessageHandler {
    weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            print("❌ Invalid audio message format: \(message.body)")
            return
        }
        
        print("📨 Received audio message: \(body)")
        tab?.handleAudioStateMessage(body)
    }
}

// MARK: - Navigation Delegate
class TabNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🔄 Navigation finished for: \(self.tab?.title ?? "unknown")")
        // Install detection after page fully loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.tab?.installEnhancedAudioDetection()
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("🔄 Navigation committed")
        DispatchQueue.main.async {
            self.tab?.isPlayingAudio = false
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🔄 Navigation started")
        DispatchQueue.main.async {
            self.tab?.isPlayingAudio = false
        }
    }
}
