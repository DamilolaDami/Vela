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
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: banner.type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(banner.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let message = banner.message {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 8)
            
            HStack(spacing: 6) {
                if let action = banner.action, let actionTitle = banner.actionTitle {
                    Button(actionTitle) {
                        action()
                        onDismiss()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(banner.type.color)
                    .buttonStyle(.plain)
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 320) // Constrain width for macOS
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(banner.type.color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
                opacity = 1
            }
        }
        .onTapGesture {
            // Optional: dismiss on tap
        }
        .gesture(
            DragGesture()
                .onEnded { value in
//                    if value.translation.y < -30 {
//                        withAnimation(.easeInOut(duration: 0.25)) {
//                            offset = -100
//                            opacity = 0
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//                            onDismiss()
//                        }
//                    }
                }
        )
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
