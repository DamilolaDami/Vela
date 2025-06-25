//
//  DownloadAnimationManager.swift
//  Vela
//
//  Created by damilola on 6/24/25.
//

import Foundation
import SwiftUI

class DownloadAnimationManager: ObservableObject {
    @Published var isTriggered = false
    @Published var tappedPosition: CGPoint = .zero
    @Published var downloadTargetPosition: CGPoint = .zero
    
    func triggerDownload(from position: CGPoint, to target: CGPoint) {
        print("tapped position: \(position), target position: \(target)")
        
        tappedPosition = position
        downloadTargetPosition = target
        isTriggered = true
    }
}
