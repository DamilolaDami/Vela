import SwiftUI

struct AddressBar: View {
    @Binding var text: String
      @Binding var isEditing: Bool
      let onCommit: () -> Void
      let currentURL: URL?
      
      @ObservedObject var suggestionVM: SuggestionViewModel
      @StateObject private var certificateService = CertificateService()
      @FocusState private var isFocused: Bool
      @State private var showingCertificate = false
      
      var body: some View {
          VStack(alignment: .leading, spacing: 0) {
              // Main address bar
              HStack(spacing: 0) {
                  // Security indicator
                  if let url = currentURL, !isEditing {
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
                              .onTapGesture {
                                  startEditing()
                              }
                      }
                      .padding(.leading, 12)
                  } else {
                      // Address input field
                      TextField("Search or enter address", text: $text)
                          .textFieldStyle(PlainTextFieldStyle())
                          .font(.system(size: 14, weight: .regular))
                          .focused($isFocused)
                          .padding(.horizontal, 12)
                          .onSubmit {
                              onCommit()
                              endEditing()
                              suggestionVM.isShowingSuggestions = false
                          }
                          .onChange(of: text) { _, newValue in
                              suggestionVM.fetchSuggestions(for: newValue)
                          }
                  }
                  
                  Spacer(minLength: 0)
                  
                  // Action buttons
                  HStack(spacing: 4) {
                      if isEditing && !text.isEmpty {
                          Button(action: clearText) {
                              Image(systemName: "xmark.circle.fill")
                                  .font(.system(size: 14))
                                  .foregroundColor(.secondary)
                          }
                          .buttonStyle(PlainButtonStyle())
                      }
                      
                      Button(action: {
                          if isEditing {
                              onCommit()
                              endEditing()
                          } else {
                              startEditing()
                          }
                      }) {
                          Image(systemName: isEditing ? "arrow.right.circle.fill" : "pencil")
                              .font(.system(size: 14))
                              .foregroundColor(.accentColor)
                      }
                      .buttonStyle(PlainButtonStyle())
                  }
                  .padding(.trailing, 8)
              }
              .frame(height: 36)
              .background(
                  RoundedRectangle(cornerRadius: 18)
                      .fill(isEditing ? .regularMaterial : .ultraThinMaterial)
                      .overlay(
                          RoundedRectangle(cornerRadius: 18)
                              .stroke(
                                  isEditing ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1),
                                  lineWidth: isEditing ? 2 : 1
                              )
                      )
              )
              .onChange(of: isEditing) { _, editing in
                  if editing {
                      isFocused = true
                  }
              }
              .onTapGesture {
                  if !isEditing {
                      startEditing()
                  }
              }
          }
          .animation(.easeInOut(duration: 0.2), value: suggestionVM.isShowingSuggestions)
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
      
      private func startEditing() {
          isEditing = true
          isFocused = true
          if let currentURL = currentURL {
              text = currentURL.absoluteString
          }
      }
      
      private func endEditing() {
          isEditing = false
          isFocused = false
          suggestionVM.clearSuggestions()
      }
      
      private func clearText() {
          text = ""
          suggestionVM.clearSuggestions()
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
