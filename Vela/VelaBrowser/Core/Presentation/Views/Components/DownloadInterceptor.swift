//
//  DownloadInterceptor.swift
//  Vela
//
//  Created by damilola on 6/24/25.
//
import SwiftUI


struct DownloadInterceptor: View {
    let downloadAnimationManager: DownloadAnimationManager
    let screenBounds: CGRect
    
    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onReceive(NotificationCenter.default.publisher(for: .downloadStarted)) { notification in
                if let userInfo = notification.userInfo,
                   var position = userInfo["screenPosition"] as? CGPoint {
                    print("\(position)")
                    position.y = position.y - 150
                    downloadAnimationManager.triggerDownload(
                        from: position,
                        to: downloadAnimationManager.downloadTargetPosition
                    )
                }
            }
    }
}
