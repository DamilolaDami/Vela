//
//  NotificationBannerView.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

struct NotificationBannerView: View {
    let banner: NotificationBanner
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -80
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: banner.type.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(banner.type.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(banner.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let message = banner.message {
                    Text(message)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 6)
            
            HStack(spacing: 4) {
                if let action = banner.action, let actionTitle = banner.actionTitle {
                    Button(actionTitle) {
                        action()
                        onDismiss()
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(banner.type.color)
                    .buttonStyle(.plain)
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: 200, minHeight: 42)
        .background(Color(NSColor.windowBackgroundColor), in: RoundedRectangle(cornerRadius: 50, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                offset = 0
                opacity = 1
            }
        }
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Banner Container View

struct NotificationBannerContainer: View {
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(notificationService.banners, id: \.id) { banner in
                NotificationBannerView(banner: banner) {
                    notificationService.dismiss(banner.id)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
