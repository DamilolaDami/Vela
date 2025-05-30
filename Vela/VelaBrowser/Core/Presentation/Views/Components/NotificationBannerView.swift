struct NotificationBannerView: View {
    let banner: NotificationBanner
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: banner.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(banner.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let message = banner.message {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let action = banner.action, let actionTitle = banner.actionTitle {
                Button(actionTitle) {
                    action()
                    onDismiss()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(banner.type.color)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(banner.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                offset = 0
                opacity = 1
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.y < -50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = -100
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }
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