//
//  NotificationType.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//


import SwiftUI
import Combine

enum NotificationType {
    case success
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct NotificationBanner {
    let id: UUID = UUID()
    let type: NotificationType
    let title: String
    let message: String?
    let duration: TimeInterval
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        type: NotificationType,
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.action = action
        self.actionTitle = actionTitle
    }
}
