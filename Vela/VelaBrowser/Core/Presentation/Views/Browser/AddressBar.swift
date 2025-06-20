import SwiftUI

struct AddressBar: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void
    let currentURL: URL?
    @ObservedObject var viewModel : BrowserViewModel
    @ObservedObject var suggestionVM: AddressBarViewModel
    @StateObject private var certificateService = CertificateService()
    @State private var showingCertificate = false
    @State private var showCopyCheckmark = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main address bar
            HStack(spacing: 0) {
                // Security indicator and URL display
                if let url = currentURL {
                    HStack(spacing: 6) {
                        Button(action: {
                            if url.scheme == "https" {
                                certificateService.fetchCertificate(for: url)
                                showingCertificate = true
                            }
                        }) {
                            Image(systemName: url.scheme == "https" ? "lock.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(url.scheme == "https" ? .green : .orange)
                        }
                        .buttonStyle(.plain)
                        .help(url.scheme == "https" ? "View Certificate" : "Not Secure")
                        
                        Text(url.host ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                    }
                    .padding(.leading, 12)
                } else {
                    // Display search placeholder when no URL is available
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("Search or enter URL...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 0) {
                    if hasURL{
                        ActionButton(
                            icon: showCopyCheckmark ? "checkmark" : "link",
                            tooltip: showCopyCheckmark ? "Copied!" : "Copy URL",
                            iconSize: 12.5
                        ) {
                            copyURL()
                        }
                    }
                    ActionButton(icon: "gear", tooltip: "Settings", iconSize: 12.5) {
                        
                    }
                }
                .padding(.trailing, 8)
            }
            .frame(height: 40)
            .animation(.spring, value: hasURL)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(NSColor.labelColor).opacity(0.1))
            )
        }
        .onChange(of: currentURL) { oldValue, newValue in
            if oldValue != newValue {
                self.text = newValue?.absoluteString ?? ""
            }
        }
        .popover(isPresented: $showingCertificate) {
            if let certificate = certificateService.certificateInfo {
                CertificateDetailView(certificate: certificate)
            } else if certificateService.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading Certificate...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 200, height: 100)
                .background(.regularMaterial)
            } else if let error = certificateService.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Certificate Error")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("OK") {
                        showingCertificate = false
                    }
                    .controlSize(.small)
                }
                .padding()
                .frame(width: 250)
                .background(.regularMaterial)
            }
        }
    }
    
    private func copyURL() {
        guard let url = viewModel.currentTab?.url else { return }
        
        #if os(iOS)
        UIPasteboard.general.string = url.absoluteString
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #endif
        
        // Show checkmark with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopyCheckmark = true
        }
        
        // Reset back to link icon after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyCheckmark = false
            }
        }
        
        NotificationService.shared.showSuccess("URL copied")
    }
    
    private var hasURL: Bool {
        viewModel.currentTab?.url != nil
    }
}

// MARK: - Real Certificate Extraction (Advanced)
extension CertificateService {
    // For production use, you'd want to implement actual certificate extraction
    // This requires more complex Security framework usage
    func getActualCertificate(for url: URL) {
        // Implementation would use URLSession with custom delegate
        // to capture the server trust and extract certificate details
        // This is more complex but provides real certificate data
    }
}
