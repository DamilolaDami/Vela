//
//  ImportFromExternalBrowserSheet.swift
//  Vela
//
//  Created by damilola on 6/21/25.
//

import SwiftUI
import AppKit

struct ImportFromExternalBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var browserDetector = BrowserDetector()
    @State private var selectedBrowser: DetectedBrowser? = nil
    @State private var selectedProfile: BrowserProfile? = nil
    @State private var isLoadingProfiles = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app icon and close button
            HStack {
                HStack(spacing: 12) {
                    // Vela app icon
                    if let appIcon = NSImage(named: "1024-mac") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.gradient)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("V")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import from Browser")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Import your data from an existing browser.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            
            Divider()
            
            // Browser and profile selection
            ScrollView {
                LazyVStack(spacing: 8) {
                    if browserDetector.detectedBrowsers.isEmpty {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Scanning for browsers...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                    } else {
                        ForEach(browserDetector.detectedBrowsers, id: \.bundleIdentifier) { browser in
                            VStack(spacing: 0) {
                                CompactBrowserOptionView(
                                    browser: browser,
                                    isSelected: selectedBrowser?.bundleIdentifier == browser.bundleIdentifier
                                ) {
                                    selectBrowser(browser)
                                }
                                
                                // Show profiles for selected browser
                                if selectedBrowser?.bundleIdentifier == browser.bundleIdentifier {
                                    ProfileSelectionView(
                                        profiles: browser.profiles,
                                        selectedProfile: selectedProfile,
                                        isLoading: isLoadingProfiles
                                    ) { profile in
                                        selectedProfile = profile
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            Divider()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(6)
                .buttonStyle(PlainButtonStyle())
                
                Button("Import") {
                    handleImport()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(canImport ? Color.accentColor : Color.gray.opacity(0.3))
                .cornerRadius(6)
                .disabled(!canImport)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 400, height: 500)
        .onAppear {
            browserDetector.detectInstalledBrowsers()
        }
    }
    
    private var canImport: Bool {
        guard let browser = selectedBrowser else { return false }
        return browser.profiles.isEmpty || selectedProfile != nil
    }
    
    private func selectBrowser(_ browser: DetectedBrowser) {
        selectedBrowser = browser
        selectedProfile = nil
        
        if !browser.profiles.isEmpty {
            // Auto-select first profile if there's only one
            if browser.profiles.count == 1 {
                selectedProfile = browser.profiles.first
            }
        } else {
            // Load profiles for this browser
            isLoadingProfiles = true
            browserDetector.loadProfiles(for: browser) {
                DispatchQueue.main.async {
                    self.isLoadingProfiles = false
                }
            }
        }
    }
    
    private func handleImport() {
        guard let browser = selectedBrowser else { return }
        
        if let profile = selectedProfile {
            print("Importing from \(browser.name) - Profile: \(profile.name) at \(profile.path)")
        } else {
            print("Importing from \(browser.name) at \(browser.path)")
        }
        
        dismiss()
    }
}

//
//  ImportFromExternalBrowserSheet.swift
//  Vela
//
//  Created by damilola on 6/21/25.
//

import SwiftUI
import AppKit


// Enhanced BrowserProfile with more metadata
struct BrowserProfile {
    let name: String
    let displayName: String
    let path: String
    let lastUsed: String?
    let avatarIconIndex: Int?
    let isActive: Bool
    
    init(name: String, displayName: String? = nil, path: String, lastUsed: Date? = nil, avatarIconIndex: Int? = nil, isActive: Bool = false) {
        self.name = name
        self.path = path
        self.lastUsed = lastUsed?.timeIntervalSinceNow.formatted()
        self.avatarIconIndex = avatarIconIndex
        self.isActive = isActive
        
        // Create display name with better logic
        if let displayName = displayName, !displayName.isEmpty {
            self.displayName = displayName
        } else if name.lowercased() == "default" {
            self.displayName = "Default Profile"
        } else if name.hasPrefix("Profile ") {
            let number = String(name.dropFirst(8))
            self.displayName = "Profile \(number)"
        } else if name.hasPrefix("Person ") {
            let number = String(name.dropFirst(7))
            self.displayName = "Person \(number)"
        } else {
            self.displayName = name
        }
    }
}

// Chrome Local State structure for parsing profile info
struct ChromeLocalState: Codable {
    let profile: ChromeProfileInfo
    
    struct ChromeProfileInfo: Codable {
        let infoCache: [String: ChromeProfileData]
        
        private enum CodingKeys: String, CodingKey {
            case infoCache = "info_cache"
        }
    }
    
    struct ChromeProfileData: Codable {
        let name: String?
        let shortcutName: String?
        let avatarIcon: String?
        let backgroundApps: Bool?
        let isOmitted: Bool?
        let isSigninRequired: Bool?
        let lastActiveTime: String?
        
        private enum CodingKeys: String, CodingKey {
            case name
            case shortcutName = "shortcut_name"
            case avatarIcon = "avatar_icon"
            case backgroundApps = "background_apps"
            case isOmitted = "is_omitted"
            case isSigninRequired = "signin_required"
            case lastActiveTime = "active_time"
        }
    }
}

extension BrowserDetector {
    
    private func detectChromeProfiles(homeDir: String) -> [BrowserProfile] {
        let chromeDir = "\(homeDir)/Library/Application Support/Google/Chrome"
        return detectChromiumProfilesWithMetadata(baseDir: chromeDir, browserType: .chrome)
    }
    
    private func detectBraveProfiles(homeDir: String) -> [BrowserProfile] {
        let braveDir = "\(homeDir)/Library/Application Support/BraveSoftware/Brave-Browser"
        return detectChromiumProfilesWithMetadata(baseDir: braveDir, browserType: .brave)
    }
    
    private func detectEdgeProfiles(homeDir: String) -> [BrowserProfile] {
        let edgeDir = "\(homeDir)/Library/Application Support/Microsoft Edge"
        return detectChromiumProfilesWithMetadata(baseDir: edgeDir, browserType: .edge)
    }
    
    private enum ChromiumBrowserType {
        case chrome, brave, edge, vivaldi, opera
    }
    
    private func detectChromiumProfilesWithMetadata(baseDir: String, browserType: ChromiumBrowserType) -> [BrowserProfile] {
        var profiles: [BrowserProfile] = []
        let fileManager = FileManager.default
        
        // First, try to read the Local State file for profile metadata
        let localStatePath = "\(baseDir)/Local State"
        var profileMetadata: [String: ChromeLocalState.ChromeProfileData] = [:]
        
        if fileManager.fileExists(atPath: localStatePath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: localStatePath))
                let localState = try JSONDecoder().decode(ChromeLocalState.self, from: data)
                profileMetadata = localState.profile.infoCache
            } catch {
                print("Warning: Could not parse Local State file: \(error)")
                // Continue without metadata
            }
        }
        
        // Check for default profile
        let defaultPath = "\(baseDir)/Default"
        if fileManager.fileExists(atPath: defaultPath) {
            let metadata = profileMetadata["Default"]
            let displayName = metadata?.name ?? metadata?.shortcutName
            let lastActiveTime = parseLastActiveTime(metadata?.lastActiveTime)
            let avatarIndex = parseAvatarIconIndex(metadata?.avatarIcon)
            
            profiles.append(BrowserProfile(
                name: "Default",
                displayName: displayName,
                path: defaultPath,
                lastUsed: lastActiveTime,
                avatarIconIndex: avatarIndex,
                isActive: false
            ))
        }
        
        // Check for additional profiles
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: baseDir)
            
            // Look for Profile directories (Profile 1, Profile 2, etc.)
            for item in contents {
                if item.hasPrefix("Profile ") && item != "Profile" {
                    let profilePath = "\(baseDir)/\(item)"
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: profilePath, isDirectory: &isDirectory) && isDirectory.boolValue {
                        let metadata = profileMetadata[item]
                        let displayName = metadata?.name ?? metadata?.shortcutName
                        let lastActiveTime = parseLastActiveTime(metadata?.lastActiveTime)
                        let avatarIndex = parseAvatarIconIndex(metadata?.avatarIcon)
                        
                        profiles.append(BrowserProfile(
                            name: item,
                            displayName: displayName,
                            path: profilePath,
                            lastUsed: lastActiveTime,
                            avatarIconIndex: avatarIndex,
                            isActive: false
                        ))
                    }
                }
            }
            
            // Also check for Person directories (newer Chrome versions)
            for item in contents {
                if item.hasPrefix("Person ") {
                    let profilePath = "\(baseDir)/\(item)"
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: profilePath, isDirectory: &isDirectory) && isDirectory.boolValue {
                        let metadata = profileMetadata[item]
                        let displayName = metadata?.name ?? metadata?.shortcutName
                        let lastActiveTime = parseLastActiveTime(metadata?.lastActiveTime)
                        let avatarIndex = parseAvatarIconIndex(metadata?.avatarIcon)
                        
                        profiles.append(BrowserProfile(
                            name: item,
                            displayName: displayName,
                            path: profilePath,
                            lastUsed: lastActiveTime,
                            avatarIconIndex: avatarIndex,
                            isActive: false
                        ))
                    }
                }
            }
            
        } catch {
            print("Error reading Chromium profiles directory: \(error)")
        }
        
        // Sort profiles: Default first, then by name
        return profiles.sorted { profile1, profile2 in
            if profile1.name == "Default" { return true }
            if profile2.name == "Default" { return false }
            return profile1.displayName < profile2.displayName
        }
    }
    
    private func parseLastActiveTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString,
              let timeInterval = Double(timeString) else { return nil }
        
        // Chrome stores time as microseconds since Windows epoch (1601-01-01)
        // Convert to Unix timestamp
        let windowsEpochOffset: TimeInterval = 11644473600 // seconds between 1601 and 1970
        let unixTimestamp = (timeInterval / 1_000_000) - windowsEpochOffset
        
        return Date(timeIntervalSince1970: unixTimestamp)
    }
    
    private func parseAvatarIconIndex(_ iconString: String?) -> Int? {
        guard let iconString = iconString else { return nil }
        
        // Chrome avatar icons are stored as "chrome://theme/IDR_PROFILE_AVATAR_X"
        if let range = iconString.range(of: "IDR_PROFILE_AVATAR_") {
            let indexString = String(iconString[range.upperBound...])
            return Int(indexString)
        }
        
        return nil
    }
    
    // Enhanced Firefox profile detection
    private func detectFirefoxProfiles(homeDir: String) -> [BrowserProfile] {
        let firefoxProfilesDir = "\(homeDir)/Library/Application Support/Firefox/Profiles"
        let firefoxInstallsPath = "\(homeDir)/Library/Application Support/Firefox/installs.ini"
        let firefoxProfilesPath = "\(homeDir)/Library/Application Support/Firefox/profiles.ini"
        
        var profiles: [BrowserProfile] = []
        let fileManager = FileManager.default
        
        // Try to read profiles.ini for profile metadata
        var profileData: [String: String] = [:]
        if fileManager.fileExists(atPath: firefoxProfilesPath) {
            profileData = parseFirefoxProfilesIni(path: firefoxProfilesPath)
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: firefoxProfilesDir)
            
            for item in contents {
                let profilePath = "\(firefoxProfilesDir)/\(item)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: profilePath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    // Firefox profile folder names are usually in format: randomstring.profilename
                    let components = item.components(separatedBy: ".")
                    let profileName = components.count > 1 ? components.dropFirst().joined(separator: ".") : item
                    
                    // Try to get display name from profiles.ini
                    let displayName = profileData[item] ?? profileName.capitalized
                    
                    // Check when profile was last used by looking at sessionstore files
                    let lastUsed = getFirefoxProfileLastUsed(profilePath: profilePath)
                    
                    profiles.append(BrowserProfile(
                        name: profileName,
                        displayName: displayName,
                        path: profilePath,
                        lastUsed: lastUsed
                    ))
                }
            }
        } catch {
            print("Error reading Firefox profiles: \(error)")
        }
        
        return profiles.sorted { $0.displayName < $1.displayName }
    }
    
    private func parseFirefoxProfilesIni(path: String) -> [String: String] {
        var profileData: [String: String] = [:]
        
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            
            var currentSection = ""
            var currentPath = ""
            var currentName = ""
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                    // Save previous profile if we have both path and name
                    if !currentPath.isEmpty && !currentName.isEmpty {
                        profileData[currentPath] = currentName
                    }
                    
                    currentSection = trimmedLine
                    currentPath = ""
                    currentName = ""
                } else if trimmedLine.hasPrefix("Path=") {
                    currentPath = String(trimmedLine.dropFirst(5))
                } else if trimmedLine.hasPrefix("Name=") {
                    currentName = String(trimmedLine.dropFirst(5))
                }
            }
            
            // Don't forget the last profile
            if !currentPath.isEmpty && !currentName.isEmpty {
                profileData[currentPath] = currentName
            }
            
        } catch {
            print("Error reading Firefox profiles.ini: \(error)")
        }
        
        return profileData
    }
    
    private func getFirefoxProfileLastUsed(profilePath: String) -> Date? {
        let sessionStorePath = "\(profilePath)/sessionstore.jsonlz4"
        let sessionStoreBackupPath = "\(profilePath)/sessionstore-backups/recovery.jsonlz4"
        
        let fileManager = FileManager.default
        
        // Check main sessionstore file first
        if fileManager.fileExists(atPath: sessionStorePath) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: sessionStorePath)
                return attributes[.modificationDate] as? Date
            } catch {
                print("Error getting sessionstore modification date: \(error)")
            }
        }
        
        // Check backup sessionstore file
        if fileManager.fileExists(atPath: sessionStoreBackupPath) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: sessionStoreBackupPath)
                return attributes[.modificationDate] as? Date
            } catch {
                print("Error getting backup sessionstore modification date: \(error)")
            }
        }
        
        return nil
    }
    
    // Enhanced Arc profile detection
    private func detectArcProfiles(homeDir: String) -> [BrowserProfile] {
        // Arc stores profiles in a different structure
        let arcDir = "\(homeDir)/Library/Application Support/Arc"
        var profiles: [BrowserProfile] = []
        let fileManager = FileManager.default
        
        // Arc profiles are typically in subdirectories
        let possiblePaths = [
            "\(arcDir)/User Data/Default",
            "\(arcDir)/User Data/Profile 1",
            "\(arcDir)/User Data/Profile 2"
        ]
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                let profileName = URL(fileURLWithPath: path).lastPathComponent
                let displayName = profileName == "Default" ? "Default Space" : "Space \(profileName.dropFirst(8))"
                
                profiles.append(BrowserProfile(
                    name: profileName,
                    displayName: displayName,
                    path: path
                ))
            }
        }
        
        return profiles
    }
}

// Enhanced TimeInterval extension with better formatting
extension TimeInterval {
    func formatted() -> String {
        let absInterval = abs(self)
        
        if absInterval < 60 { // Less than 1 minute
            return "Just now"
        } else if absInterval < 3600 { // Less than 1 hour
            let minutes = Int(absInterval / 60)
            return "\(minutes)m ago"
        } else if absInterval < 86400 { // Less than 1 day
            let hours = Int(absInterval / 3600)
            return "\(hours)h ago"
        } else if absInterval < 604800 { // Less than 1 week
            let days = Int(absInterval / 86400)
            return "\(days)d ago"
        } else if absInterval < 2592000 { // Less than 30 days
            let weeks = Int(absInterval / 604800)
            return "\(weeks)w ago"
        } else {
            let months = Int(absInterval / 2592000)
            return "\(months)mo ago"
        }
    }
}
struct CompactBrowserOptionView: View {
    let browser: DetectedBrowser
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Browser icon
                if let icon = browser.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(browser.name.prefix(1)))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        )
                }
                
                // Browser info
                VStack(alignment: .leading, spacing: 1) {
                    Text(browser.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        if let version = browser.version {
                            Text("v\(version)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !browser.profiles.isEmpty {
                            Text("• \(browser.profiles.count) profile\(browser.profiles.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileSelectionView: View {
    let profiles: [BrowserProfile]
    let selectedProfile: BrowserProfile?
    let isLoading: Bool
    let onProfileSelected: (BrowserProfile) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Loading profiles...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if profiles.isEmpty {
                Text("No profiles found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(profiles, id: \.path) { profile in
                    ProfileOptionView(
                        profile: profile,
                        isSelected: selectedProfile?.path == profile.path
                    ) {
                        onProfileSelected(profile)
                    }
                }
            }
        }
        .padding(.leading, 36) // Indent to align with browser name
        .padding(.trailing, 12)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.03))
        )
    }
}

struct ProfileOptionView: View {
    let profile: BrowserProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Profile icon
                Circle()
                    .fill(profileColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(profileInitial)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    )
                
                // Profile info
                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let lastUsed = profile.lastUsed {
                        Text("Last used \(lastUsed)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3, height: 3)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var profileColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .indigo, .teal]
        let index = abs(profile.name.hashValue) % colors.count
        return colors[index]
    }
    
    private var profileInitial: String {
        String(profile.displayName.prefix(1).uppercased())
    }
}



struct DetectedBrowser {
    let name: String
    let displayName: String
    let bundleIdentifier: String
    let path: String
    let icon: NSImage?
    let version: String?
    var profiles: [BrowserProfile] = []
    
    init(name: String, displayName: String, bundleIdentifier: String, path: String) {
        self.name = name
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        
        // Get app icon
        if let bundle = Bundle(url: URL(fileURLWithPath: path)),
           let iconFile = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
            self.icon = bundle.image(forResource: iconFile)
        } else {
            self.icon = NSWorkspace.shared.icon(forFile: path)
        }
        
        // Get version
        if let bundle = Bundle(url: URL(fileURLWithPath: path)),
           let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            self.version = version
        } else {
            self.version = nil
        }
    }
}

class BrowserDetector: ObservableObject {
    @Published var detectedBrowsers: [DetectedBrowser] = []
    
    private let knownBrowsers = [
        ("Safari", "Safari", "com.apple.Safari"),
        ("Google Chrome", "Chrome", "com.google.Chrome"),
        ("Mozilla Firefox", "Firefox", "org.mozilla.firefox"),
        ("Brave Browser", "Brave", "com.brave.Browser"),
        ("Microsoft Edge", "Edge", "com.microsoft.edgemac"),
        ("Opera", "Opera", "com.operasoftware.Opera"),
        ("Arc", "Arc", "company.thebrowser.Browser"),
        ("Vivaldi", "Vivaldi", "com.vivaldi.Vivaldi"),
        ("DuckDuckGo Privacy Browser", "DuckDuckGo", "com.duckduckgo.macos.browser"),
        ("Tor Browser", "Tor", "org.torproject.torbrowser"),
        ("Chromium", "Chromium", "org.chromium.Chromium")
    ]
    
    func detectInstalledBrowsers() {
        DispatchQueue.global(qos: .userInitiated).async {
            var browsers: [DetectedBrowser] = []
            
            for (name, displayName, bundleId) in self.knownBrowsers {
                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    var browser = DetectedBrowser(
                        name: name,
                        displayName: displayName,
                        bundleIdentifier: bundleId,
                        path: appURL.path
                    )
                    
                    // Load profiles immediately for quick access
                    browser.profiles = self.detectProfiles(for: browser)
                    browsers.append(browser)
                }
            }
            
            // Sort by name
            browsers.sort { $0.displayName < $1.displayName }
            
            DispatchQueue.main.async {
                self.detectedBrowsers = browsers
            }
        }
    }
    
    func loadProfiles(for browser: DetectedBrowser, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiles = self.detectProfiles(for: browser)
            
            DispatchQueue.main.async {
                if let index = self.detectedBrowsers.firstIndex(where: { $0.bundleIdentifier == browser.bundleIdentifier }) {
                    self.detectedBrowsers[index].profiles = profiles
                }
                completion()
            }
        }
    }
    
    private func detectProfiles(for browser: DetectedBrowser) -> [BrowserProfile] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        var profiles: [BrowserProfile] = []
        
        switch browser.bundleIdentifier {
        case "com.google.Chrome":
            profiles = detectChromeProfiles(homeDir: homeDir)
        case "com.brave.Browser":
            profiles = detectBraveProfiles(homeDir: homeDir)
        case "com.microsoft.edgemac":
            profiles = detectEdgeProfiles(homeDir: homeDir)
        case "org.mozilla.firefox":
            profiles = detectFirefoxProfiles(homeDir: homeDir)
        case "com.apple.Safari":
            // Safari doesn't have multiple profiles in the same way
            profiles = []
        case "company.thebrowser.Browser": // Arc
            profiles = detectArcProfiles(homeDir: homeDir)
        default:
            profiles = []
        }
        
        return profiles
    }
    
    
    private func detectChromiumProfiles(baseDir: String) -> [BrowserProfile] {
        var profiles: [BrowserProfile] = []
        let fileManager = FileManager.default
        
        // Check for default profile
        if fileManager.fileExists(atPath: "\(baseDir)/Default") {
            profiles.append(BrowserProfile(name: "Default", path: "\(baseDir)/Default"))
        }
        
        // Check for additional profiles (Profile 1, Profile 2, etc.)
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: baseDir)
            for item in contents {
                if item.hasPrefix("Profile ") && fileManager.fileExists(atPath: "\(baseDir)/\(item)") {
                    profiles.append(BrowserProfile(name: item, path: "\(baseDir)/\(item)"))
                }
            }
        } catch {
            print("Error reading Chrome profiles: \(error)")
        }
        
        return profiles.sorted { $0.name < $1.name }
    }
    


}
