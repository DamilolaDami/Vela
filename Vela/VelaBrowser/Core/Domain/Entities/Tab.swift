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
    @Published var folderId: UUID?

    @Published var scrollPosition: Double = 0
    @Published var zoomLevel: CGFloat = 1.0 // Default zoom level (100%)
    @Published var isZooming: Bool = false
    private var zoomIndicatorTimer: Timer?

    // Minimum and maximum zoom levels
    private let minZoomLevel: CGFloat = 0.5  // 50%
    private let maxZoomLevel: CGFloat = 2.0  // 200%
    private let zoomStep: CGFloat = 0.1
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
    @Published var hasLoadFailed: Bool = false
    // Store the last load error for display
    var lastLoadError: Error? = nil
    
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
        position: Int = 0,
        folderId: UUID?
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
        self.folderId = folderId
        
        setupFaviconObserver()
    }
    
    func reloadFavicon() {
        if let url = self.url {
            loadFavicon(for: url)
        }
    }
    
    private func setupFaviconObserver() {
        $url
            .compactMap { $0 } // Filter out nil URLs
            .sink { [weak self] url in
                guard let self = self else { return }
                print("🔍 URL changed, triggering favicon load for: \(url.absoluteString)")
                self.loadFavicon(for: url)
            }
            .store(in: &cancellables)
    }
    
    private var faviconLoadQueue: [(URL, Int)] = [] // (URL, retryCount)
    private let maxFaviconRetries = 3
    private var currentFaviconTask: AnyCancellable?
     var isLoadingFavicon = false

    func loadFavicon(for url: URL) {
        // Prevent multiple simultaneous favicon loads
        guard !isLoadingFavicon else {
            return
        }
        
        guard let webView = webView else {
            if faviconLoadQueue.first(where: { $0.0 == url }) == nil && faviconLoadQueue.count < 10 {
                faviconLoadQueue.append((url, 0))
                print("📋 Queued favicon load for: \(url)")
                checkFaviconQueue()
            }
            return
        }
        
        guard !webView.isLoading else {
            if faviconLoadQueue.first(where: { $0.0 == url }) == nil && faviconLoadQueue.count < 10 {
                faviconLoadQueue.append((url, 0))
                checkFaviconQueue()
            }
            return
        }
        
        isLoadingFavicon = true
        
        // Cancel any existing favicon task
        currentFaviconTask?.cancel()
        
        // Reset favicon to trigger UI update
        self.favicon = nil
        
        let faviconJS = """
        (function() {
            let link = document.querySelector('link[rel="icon"], link[rel="shortcut icon"], link[rel="apple-touch-icon"], link[rel="apple-touch-icon-precomposed"]');
            if (link && link.href) {
                return link.href;
            }
            let meta = document.querySelector('meta[itemprop="image"]');
            if (meta && meta.content) {
                return meta.content;
            }
            return null;
        })();
        """
        
        webView.evaluateJavaScript(faviconJS) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to evaluate favicon JavaScript: \(error)")
                self.isLoadingFavicon = false
                return
            }
            
            var faviconURLs: [URL] = []
            
            // Try JavaScript-discovered favicon first
            if let faviconURLString = result as? String,
               let jsURL = URL(string: faviconURLString, relativeTo: url) {
                faviconURLs.append(jsURL)
            }
            
            // Add common favicon paths as fallbacks
            let commonPaths = [
                "/favicon.ico",
                "/apple-touch-icon.png",
                "/favicon.png",
                "/favicon.jpg",
                "/favicon.svg"
            ]
            
            for path in commonPaths {
                // Fix URL construction to avoid malformed URLs
                if let baseURL = URL(string: url.scheme! + "://" + (url.host ?? "")) {
                    let faviconURL = baseURL.appendingPathComponent(path)
                    if !faviconURLs.contains(faviconURL) {
                        faviconURLs.append(faviconURL)
                    }
                }
            }
            
            if faviconURLs.isEmpty {
                self.isLoadingFavicon = false
                return
            }
            
            self.tryFaviconURLs(faviconURLs, originalURL: url)
        }
    }

    private func tryFaviconURLs(_ urls: [URL], originalURL: URL, index: Int = 0) {
        guard index < urls.count else {
            isLoadingFavicon = false
            return
        }
        
        let faviconURL = urls[index]
        
        // Create a proper URL with cache-busting parameter
        guard var components = URLComponents(url: faviconURL, resolvingAgainstBaseURL: true) else {
            print("❌ Invalid favicon URL: \(faviconURL)")
            tryFaviconURLs(urls, originalURL: originalURL, index: index + 1)
            return
        }
        
        components.queryItems = [URLQueryItem(name: "t", value: "\(Date().timeIntervalSince1970)")]
        
        guard let finalURL = components.url else {
            print("❌ Failed to construct favicon URL")
            tryFaviconURLs(urls, originalURL: originalURL, index: index + 1)
            return
        }
        
        // Create request with timeout
        var request = URLRequest(url: finalURL)
        request.timeoutInterval = 10.0
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        
        currentFaviconTask = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                // Validate response
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                guard !output.data.isEmpty else {
                    throw URLError(.zeroByteResource)
                }
                
                // Basic image validation
                let data = output.data
                guard data.count > 16 else {
                    throw URLError(.badServerResponse)
                }
                
                // Check for common image signatures
                let header = data.prefix(16)
                let isValidImage = header.starts(with: [0x89, 0x50, 0x4E, 0x47]) || // PNG
                                  header.starts(with: [0xFF, 0xD8, 0xFF]) || // JPEG
                                  header.starts(with: [0x47, 0x49, 0x46]) || // GIF
                                  header.starts(with: [0x3C, 0x73, 0x76, 0x67]) || // SVG (starts with <svg)
                                  header.starts(with: [0x00, 0x00, 0x01, 0x00]) // ICO
                
                guard isValidImage else {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .timeout(10.0, scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .failure(let error):
                    // Try next URL
                    self.tryFaviconURLs(urls, originalURL: originalURL, index: index + 1)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                
                self.favicon = data
                self.isLoadingFavicon = false
                
                // Clear the task reference
                self.currentFaviconTask = nil
            }
    }

    // Remove the old tryAlternativeFaviconPaths method since it's now integrated above

    private func checkFaviconQueue() {
        guard !faviconLoadQueue.isEmpty else { return }
        guard !isLoadingFavicon else {
            // Wait for current favicon load to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.checkFaviconQueue()
            }
            return
        }
        
        guard webView != nil else {
            faviconLoadQueue.removeAll()
            return
        }
        
        let (url, retryCount) = faviconLoadQueue.removeFirst()
        
        if retryCount >= maxFaviconRetries {
            print("❌ Max retries reached for favicon load: \(url)")
            checkFaviconQueue() // Process next item
            return
        }
        
        guard !webView!.isLoading else {
            faviconLoadQueue.append((url, retryCount + 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkFaviconQueue()
            }
            return
        }
        loadFavicon(for: url)
    }

    private func fetchFavicon(from url: URL) {
        // Add cache-busting query parameter to avoid stale favicons
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("❌ Invalid favicon URL: \(url)")
            return
        }
        components.queryItems = [URLQueryItem(name: "t", value: "\(Date().timeIntervalSince1970)")]

        guard let finalURL = components.url else {
            print("❌ Failed to construct favicon URL")
            return
        }

        URLSession.shared.dataTaskPublisher(for: finalURL)
            .tryMap { output in
                guard !output.data.isEmpty, output.response.mimeType?.contains("image") == true else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to fetch favicon from \(finalURL): \(error)")
                    // Try alternative favicon paths as a fallback
                    self?.tryAlternativeFaviconPaths(for: url)
                }
            } receiveValue: { [weak self] data in
                self?.favicon = data
              
            }
            .store(in: &cancellables)
    }

    private func tryAlternativeFaviconPaths(for url: URL) {
        // Try common alternative favicon paths
        let alternativePaths = [
            "/apple-touch-icon.png",
            "/favicon.png",
            "/favicon.jpg",
            "/favicon.svg"
        ]

        for path in alternativePaths {
            let alternativeURL = url.deletingLastPathComponent().appendingPathComponent(path)
            fetchFavicon(from: alternativeURL)
        }
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
        DispatchQueue.main.async {
            self.isPlayingAudio = false
            self.applyZoom()
        }
        
        // Existing setup code...
        navigationDelegate = TabNavigationDelegate(tab: self, errorHandler: Tab.sharedErrorHandler)
        webView.navigationDelegate = navigationDelegate
        setupAudioMessageHandler(webView)
        setupWebViewObservers()
        setupNativeMediaObservers()
        startAudioCheckTimer()
    }
    func startZoomIndicator() {
        isZooming = true
        zoomIndicatorTimer?.invalidate()
        zoomIndicatorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.isZooming = false
        }
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
        
    }
    
    private func stopAudioCheckTimer() {
        audioCheckTimer?.invalidate()
        audioCheckTimer = nil
      
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
        
        // Observe canGoBack
        webViewObservers.append(
            webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, change in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.canGoBack = webView.canGoBack
                    print("🔄 Tab \(self.id): canGoBack updated to \(self.canGoBack)")
                }
            }
        )
        
        // Observe canGoForward
        webViewObservers.append(
            webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, change in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.canGoForward = webView.canGoForward
                    print("🔄 Tab \(self.id): canGoForward updated to \(self.canGoForward)")
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
    
    @objc func loadFaviconDelayed(_ url: URL) {
        loadFavicon(for: url)
    }
    
    // MARK: - Cleanup
    private func cleanupWebView(_ webView: WKWebView) {
        // Cancel any ongoing favicon task
        currentFaviconTask?.cancel()
        currentFaviconTask = nil
        isLoadingFavicon = false
        
        webViewObservers.forEach { $0.invalidate() }
        webViewObservers.removeAll()
        faviconLoadQueue.removeAll()
        cancellables.removeAll()
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

    
    func setZoomLevel(_ newZoomLevel: CGFloat) {
            let clampedZoom = max(minZoomLevel, min(newZoomLevel, maxZoomLevel))
            guard zoomLevel != clampedZoom else { return }
            
            zoomLevel = clampedZoom
            startZoomIndicator()
            applyZoom()
        }

        // Increase zoom level
        func zoomIn() {
            setZoomLevel(zoomLevel + zoomStep)
        }

        // Decrease zoom level
        func zoomOut() {
            setZoomLevel(zoomLevel - zoomStep)
        }

        // Reset zoom to default (100%)
        func resetZoom() {
            setZoomLevel(1.0)
        }

        // Apply zoom to the webView
        private func applyZoom() {
            guard let webView = webView else { return }
            
            DispatchQueue.main.async {
                webView.setMagnification(self.zoomLevel, centeredAt: .zero)
                // Optionally inject JavaScript to adjust viewport for better compatibility
                let js = """
                (function() {
                    let meta = document.querySelector('meta[name="viewport"]');
                    if (!meta) {
                        meta = document.createElement('meta');
                        meta.name = 'viewport';
                        document.head.appendChild(meta);
                    }
                    meta.content = 'width=device-width, initial-scale=\(self.zoomLevel), user-scalable=yes';
                })();
                """
                webView.evaluateJavaScript(js) { _, error in
                    if let error = error {
                        print("❌ Failed to adjust viewport: \(error.localizedDescription)")
                    }
                }
            }
        }
    
    deinit {
        zoomIndicatorTimer?.invalidate()
        if let webView = self.webView {
            cleanupWebView(webView)
        }
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
    private let errorHandler: TabErrorHandler
    private var loadingStartTime: Date?
    private let loadingTimeout: TimeInterval = 30.0
    private var timeoutTimer: Timer?
    
    init(tab: Tab, errorHandler: TabErrorHandler) {
        self.tab = tab
        self.errorHandler = errorHandler
        super.init()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingStartTime = Date()
        
        // Set timeout timer
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: loadingTimeout, repeats: false) { [weak self] _ in
            self?.handleLoadingTimeout(webView: webView)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isPlayingAudio = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isPlayingAudio = false
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        timeoutTimer?.invalidate()
        loadingStartTime = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.canGoBack = webView.canGoBack
            tab.canGoForward = webView.canGoForward
            
            // Install audio detection after successful load
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                tab.installEnhancedAudioDetection()
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(navigation: navigation, error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(navigation: navigation, error: error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let error = TabError.webProcessCrash(tabId: tab?.id ?? UUID())
        errorHandler.handleError(error, context: [
            "webView": webView,
            "url": webView.url as Any
        ])
    }
    
    private func handleNavigationError(navigation: WKNavigation?, error: Error) {
        timeoutTimer?.invalidate()
        loadingStartTime = nil
        
        guard let tab = self.tab else { return }
        
        DispatchQueue.main.async {
            tab.isLoading = false
        }
        
        let nsError = error as NSError
        if nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled {
            let tabError = TabError.navigationFailed(url: tab.url, error: error)
            errorHandler.handleError(tabError, context: [
                "navigation": navigation as Any,
                "errorDomain": nsError.domain,
                "errorCode": nsError.code
            ])
        }
    }
    
    private func handleLoadingTimeout(webView: WKWebView) {
        guard let tab = self.tab else { return }
        
        let duration = loadingStartTime?.timeIntervalSinceNow.magnitude ?? 0
        let error = TabError.loadingTimeout(url: webView.url, duration: duration)
        
        errorHandler.handleError(error, context: [
            "webView": webView,
            "expectedTimeout": loadingTimeout
        ])
        
        // Stop the loading
        webView.stopLoading()
        
        DispatchQueue.main.async {
            tab.isLoading = false
        }
    }
    
    deinit {
        timeoutTimer?.invalidate()
    }
}


extension Tab {
    func loadURLSafely(_ url: URL) async throws {
        guard let webView = webView else {
            throw TabError.navigationFailed(url: url, error: NSError(domain: "Tab", code: -1, userInfo: [NSLocalizedDescriptionKey: "No web view available"]))
        }
        let request = URLRequest(url: url)
        do {
            _ = try await webView.load(request)
            self.url = url
            try await loadFaviconWithErrorHandling(for: url)
        } catch {
            handleError(TabError.navigationFailed(url: url, error: error), context: ["source": "loadURLSafely"])
            throw error
        }
    }
    
    func reloadSafely() throws {
        guard let webView = webView, let url = url else {
            throw TabError.navigationFailed(url: nil, error: NSError(domain: "Tab", code: -1, userInfo: [NSLocalizedDescriptionKey: "No web view or URL available"]))
        }
        do {
            webView.reload()
            try loadFaviconWithErrorHandling(for: url)
        } catch {
            handleError(TabError.navigationFailed(url: url, error: error), context: ["source": "reloadSafely"])
            throw error
        }
    }
    
    func stopLoadingSafely() throws {
        guard let webView = webView else {
            throw TabError.navigationFailed(url: nil, error: NSError(domain: "Tab", code: -1, userInfo: [NSLocalizedDescriptionKey: "No web view available"]))
        }
        do {
            webView.stopLoading()
        } catch {
            handleError(TabError.navigationFailed(url: url, error: error), context: ["source": "stopLoadingSafely"])
            throw error
        }
    }
    
    func navigateBack() throws {
        guard let webView = webView, canGoBack else {
            throw TabError.navigationFailed(url: url, error: NSError(domain: "Tab", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot navigate back"]))
        }
        do {
            webView.goBack()
        } catch {
            handleError(TabError.navigationFailed(url: url, error: error), context: ["source": "navigateBack"])
            throw error
        }
    }
    
    func navigateForward() throws {
        guard let webView = webView, canGoForward else {
            throw TabError.navigationFailed(url: url, error: NSError(domain: "Tab", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot navigate forward"]))
        }
        do {
            webView.goForward()
        } catch {
            handleError(TabError.navigationFailed(url: url, error: error), context: ["source": "navigateForward"])
            throw error
        }
    }
}
