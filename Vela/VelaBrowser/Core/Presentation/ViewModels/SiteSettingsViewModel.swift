//
//  PermissionSetting.swift
//  Vela
//
//  Created by damilola on 6/20/25.
//


import SwiftUI
import Foundation

enum PermissionSetting: String, CaseIterable, Codable {
    case ask = "Ask"
    case allow = "Allow"
    case deny = "Deny"
}

// MARK: - Site Settings Model
struct SiteSettings: Codable, Identifiable {
    let id = UUID()
    let host: String
    var displayName: String
    var lastUpdated: Date
    
    // Privacy & Security Settings
    var isAdBlockingEnabled: Bool
    var isPopupBlockingEnabled: Bool
    
    // Permission Settings
    var cameraPermission: PermissionSetting
    var microphonePermission: PermissionSetting
    var screenSharingPermission: PermissionSetting
    var locationPermission: PermissionSetting
    var notificationPermission: PermissionSetting
    
    // Developer Settings
    var isJavaScriptEnabled: Bool
    
    init(host: String, displayName: String? = nil) {
        self.host = host
        self.displayName = displayName ?? host
        self.lastUpdated = Date()
        
        // Default settings - can be customized based on your app's defaults
        self.isAdBlockingEnabled = true
        self.isPopupBlockingEnabled = true
        self.isJavaScriptEnabled = true
        
        // Default all permissions to "Ask"
        self.cameraPermission = .ask
        self.microphonePermission = .ask
        self.screenSharingPermission = .ask
        self.locationPermission = .ask
        self.notificationPermission = .ask
    }
}

// MARK: - Site Settings Manager
class SiteSettingsManager: ObservableObject {
    static let shared = SiteSettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "VelaSiteSettings"
    
    @Published private var siteSettingsStore: [String: SiteSettings] = [:]
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func getSettings(for url: URL) -> SiteSettings {
        let host = extractHost(from: url)
        
        if let existingSettings = siteSettingsStore[host] {
            return existingSettings
        } else {
            // Create new settings for this site
            let newSettings = SiteSettings(host: host, displayName: url.host)
            siteSettingsStore[host] = newSettings
            saveSettings()
            return newSettings
        }
    }
    
    func updateSettings(_ settings: SiteSettings) {
        var updatedSettings = settings
        updatedSettings.lastUpdated = Date()
        siteSettingsStore[settings.host] = updatedSettings
        saveSettings()
    }
    
    func getAllSiteSettings() -> [SiteSettings] {
        return Array(siteSettingsStore.values).sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func deleteSiteSettings(for host: String) {
        siteSettingsStore.removeValue(forKey: host)
        saveSettings()
    }
    
    func clearAllSettings() {
        siteSettingsStore.removeAll()
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func extractHost(from url: URL) -> String {
        return url.host?.lowercased() ?? url.absoluteString
    }
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey),
              let decodedSettings = try? JSONDecoder().decode([String: SiteSettings].self, from: data) else {
            return
        }
        siteSettingsStore = decodedSettings
    }
    
    private func saveSettings() {
        guard let encodedData = try? JSONEncoder().encode(siteSettingsStore) else {
            print("Failed to encode site settings")
            return
        }
        userDefaults.set(encodedData, forKey: settingsKey)
    }
}

// MARK: - Site Settings View Model
class SiteSettingsViewModel: ObservableObject {
    @Published var currentSettings: SiteSettings
    private let settingsManager = SiteSettingsManager.shared
    private let siteUrl: URL
    
    init(siteUrl: URL) {
        self.siteUrl = siteUrl
        self.currentSettings = settingsManager.getSettings(for: siteUrl)
    }
    
    // MARK: - Privacy & Security Updates
    
    func updateAdBlocking(enabled: Bool) {
        currentSettings.isAdBlockingEnabled = enabled
        saveSettings()
    }
    
    func updatePopupBlocking(enabled: Bool) {
        currentSettings.isPopupBlockingEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Permission Updates
    
    func updateCameraPermission(setting: PermissionSetting) {
        currentSettings.cameraPermission = setting
        saveSettings()
    }
    
    func updateMicrophonePermission(setting: PermissionSetting) {
        currentSettings.microphonePermission = setting
        saveSettings()
    }
    
    func updateScreenSharingPermission(setting: PermissionSetting) {
        currentSettings.screenSharingPermission = setting
        saveSettings()
    }
    
    func updateLocationPermission(setting: PermissionSetting) {
        currentSettings.locationPermission = setting
        saveSettings()
    }
    
    func updateNotificationPermission(setting: PermissionSetting) {
        currentSettings.notificationPermission = setting
        saveSettings()
    }
    
    // MARK: - Developer Updates
    
    func updateJavaScript(enabled: Bool) {
        currentSettings.isJavaScriptEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Helper Methods
    
    private func saveSettings() {
        settingsManager.updateSettings(currentSettings)
    }
    
    func resetToDefaults() {
        currentSettings = SiteSettings(host: currentSettings.host, displayName: currentSettings.displayName)
        saveSettings()
    }
}