//
//  NotificationService.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import Foundation


class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var banners: [NotificationBanner] = []
    private var timers: [UUID: Timer] = [:]
    
    private init() {}
    
    func show(
        type: NotificationType,
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        let banner = NotificationBanner(
            type: type,
            title: title,
            message: message,
            duration: duration,
            action: action,
            actionTitle: actionTitle
        )
        
        DispatchQueue.main.async {
            self.banners.append(banner)
            
            if duration > 0 {
                let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    self.dismiss(banner.id)
                }
                self.timers[banner.id] = timer
            }
        }
    }
    
    func dismiss(_ id: UUID) {
        DispatchQueue.main.async {
            self.banners.removeAll { $0.id == id }
            self.timers[id]?.invalidate()
            self.timers.removeValue(forKey: id)
        }
    }
    
    func dismissAll() {
        DispatchQueue.main.async {
            self.banners.removeAll()
            self.timers.values.forEach { $0.invalidate() }
            self.timers.removeAll()
        }
    }
    
    // Convenience methods
    func showSuccess(_ title: String, message: String? = nil) {
        show(type: .success, title: title, message: message)
    }
    
    func showError(_ title: String, message: String? = nil) {
        show(type: .error, title: title, message: message)
    }
    
    func showWarning(_ title: String, message: String? = nil) {
        show(type: .warning, title: title, message: message)
    }
    
    func showInfo(_ title: String, message: String? = nil) {
        show(type: .info, title: title, message: message)
    }
}
