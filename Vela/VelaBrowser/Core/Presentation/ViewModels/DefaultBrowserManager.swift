//
//  DefaultBrowserManager.swift
//  Vela
//
//  Created by damilola on 6/17/25.
//

import Foundation
import CoreServices

class DefaultBrowserManager: ObservableObject {
    @Published var isDefault = false
    @Published var showPrompt = false
    
    private var sessionCount: Int {
        get { UserDefaults.standard.integer(forKey: "vela_sessions") }
        set { UserDefaults.standard.set(newValue, forKey: "vela_sessions") }
    }
    
    private var lastPrompt: Date? {
        get { UserDefaults.standard.object(forKey: "vela_last_prompt") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "vela_last_prompt") }
    }
    
    init() {
        sessionCount += 1
        checkIfDefault()
        
        if shouldShowPrompt() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showPrompt = true
            }
        }
    }
    
    func checkIfDefault() {
        if let handler = LSCopyDefaultHandlerForURLScheme("http" as CFString)?.takeRetainedValue() as String? {
            isDefault = (handler == Bundle.main.bundleIdentifier)
        }
    }
    
    func setAsDefault() {
        let scheme = "http" as CFString
        let bundleID = Bundle.main.bundleIdentifier! as CFString
        LSSetDefaultHandlerForURLScheme(scheme, bundleID)
        
        lastPrompt = Date()
        showPrompt = false
        checkIfDefault()
    }
    
    func dismissPrompt() {
        lastPrompt = Date()
        showPrompt = false
    }
    
    private func shouldShowPrompt() -> Bool {
        guard !isDefault else { return false }
        guard sessionCount >= 3 else { return false }
        
        if let last = lastPrompt {
            let daysSince = Date().timeIntervalSince(last) / (24 * 60 * 60)
            return daysSince >= 7
        }
        
        return true
    }
}
