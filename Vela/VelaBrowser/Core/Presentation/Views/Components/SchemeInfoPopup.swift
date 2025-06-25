//
//  SchemeInfoPopup.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//

import SwiftUI
import Kingfisher

struct SchemeInfoPopup: View {
    var detector: SchemaDetectionService
    var color: Color
    @State private var isVisible = false
    @State private var currentSchemaType: DetectedSchemaType = .unknown
    @State private var isSaving = false
    @State private var saveCompleted = false
    
    private var hasSchemas: Bool {
        !detector.detectedSchemas.isEmpty
    }
    
    private var schemaCount: Int {
        detector.detectedSchemas.count
    }
    
    private var primarySchema: DetectedSchema? {
        detector.detectedSchemas.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if hasSchemas && isVisible {
                // Main capsule
                mainCapsule
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.8)),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .onChange(of: hasSchemas) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
                // Update current schema type when schemas are detected
                currentSchemaType = primarySchema?.type ?? .unknown
            } else {
                // Only hide when there are no schemas detected
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = false
                }
            }
        }
        .onChange(of: primarySchema?.type) { _, newSchemaType in
            guard let newType = newSchemaType else { return }
            
            // If schema type changed and popup is visible, redo the animation
            if newType != currentSchemaType && isVisible {
                currentSchemaType = newType
                
                // Hide first, then show again with new content
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    isVisible = false
                }
                
                // Show again after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isVisible = true
                    }
                }
            } else if newType != currentSchemaType {
                // Update type even if not visible
                currentSchemaType = newType
            }
        }
    }
    
    private var mainCapsule: some View {
        HStack(spacing: 8) {
            // Schema image or icon
            schemaImageView(for: primarySchema, size: 24)
            
            // Text content
            VStack(alignment: .leading, spacing: 1) {
                Text(saveCompleted ? "Schemas saved!" : "\(primarySchema?.type.rawValue.capitalized ?? "Schema") detected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.3), value: saveCompleted)
                
                if let title = primarySchema?.title, !saveCompleted {
                    Text(title)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                } else if saveCompleted {
                    Text("Successfully saved \(schemaCount) schema\(schemaCount == 1 ? "" : "s")")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            
            Spacer(minLength: 8)
            
            // Action buttons
            HStack(spacing: 6) {
                // Save button with progress state
                if !saveCompleted {
                    Button(action: saveSchemas) {
                        HStack(spacing: 4) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.7)
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(isSaving ? "Working..." : "Save")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                    .onHover { hovering in
                        // Add subtle hover effect
                    }
                } else {
                    // Show checkmark when completed
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Saved")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Close button
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: saveCompleted ? [.green, .green.opacity(0.8)] : [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.5), value: saveCompleted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .clipShape(Capsule())
        .shadow(color: (saveCompleted ? .green : color).opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: (saveCompleted ? .green : color).opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    @ViewBuilder
    private func schemaImageView(for schema: DetectedSchema?, size: CGFloat) -> some View {
        if let schema = schema,
           let imageURL = schema.imageURL,
           let url = URL(string: imageURL) {
            // Use Kingfisher to load the image
            KFImage(url)
                .placeholder {
                    // Placeholder while loading
                    ZStack {
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .fill(Color.gray.opacity(0.2))
                        
                        Image(systemName: iconForSchema(schema.type))
                            .foregroundColor(.gray)
                            .font(.system(size: size * 0.4, weight: .medium))
                    }
                }
                .loadDiskFileSynchronously()
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .onProgress { receivedSize, totalSize in
                    // Optional: Handle progress if needed
                }
                .onSuccess { result in
                    // Optional: Handle success
                }
                .onFailure { error in
                    // Optional: Handle failure
                    print("Failed to load image: \(error)")
                }
                .cancelOnDisappear(true)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        } else {
            // Fallback to icon when no image URL
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(schemaTypeColor(schema?.type ?? .unknown).opacity(0.2))
                
                Image(systemName: iconForSchema(schema?.type ?? .unknown))
                    .foregroundColor(schemaTypeColor(schema?.type ?? .unknown))
                    .font(.system(size: size * 0.4, weight: .medium))
            }
            .frame(width: size, height: size)
        }
    }
    
    private func iconForSchema(_ type: DetectedSchemaType) -> String {
        switch type {
        case .recipe:
            return "fork.knife"
        case .product:
            return "tag"
        case .event:
            return "calendar"
        case .article, .newsArticle:
            return "doc.text"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func schemaTypeColor(_ type: DetectedSchemaType) -> Color {
        switch type {
        case .recipe:
            return .orange
        case .product:
            return .green
        case .event:
            return .purple
        case .article, .newsArticle:
            return color
        case .unknown:
            return .gray
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }
        
        // Reset states when dismissing
        isSaving = false
        saveCompleted = false
    }
    
    private func saveSchemas() {
        // Start saving animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isSaving = true
        }
        
        print("Saving \(detector.detectedSchemas.count) schemas...")
        
        // Simulate async save operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isSaving = false
                saveCompleted = true
            }
            
            // Auto dismiss after showing success state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }
}
