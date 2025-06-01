//
//  CertificateInfo.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI
import Security
import Network
import CommonCrypto

// MARK: - Certificate Models
struct CertificateInfo {
    let commonName: String
    let organization: String
    let organizationalUnit: String
    let country: String
    let validFrom: Date
    let validTo: Date
    let serialNumber: String
    let issuer: String
    let fingerprint: String
    let keySize: String
    let signatureAlgorithm: String
    
    var isValid: Bool {
        let now = Date()
        return now >= validFrom && now <= validTo
    }
    
    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validTo).day ?? 0
    }
}

// MARK: - Certificate Service
class CertificateService: ObservableObject {
    @Published var certificateInfo: CertificateInfo?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchCertificate(for url: URL) {
        guard let host = url.host else {
            DispatchQueue.main.async {
                self.error = "Invalid URL: No host found"
                self.isLoading = false
            }
            return
        }
        
        isLoading = true
        error = nil
        
        // Create connection to get certificate
        let queue = DispatchQueue(label: "certificate.fetch")
        
        queue.async {
            self.getCertificateInfo(host: host, port: url.port ?? 443) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let info):
                        self.certificateInfo = info
                    case .failure(let error):
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func getCertificateInfo(host: String, port: Int, completion: @escaping (Result<CertificateInfo, Error>) -> Void) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(port))!)
        let parameters = NWParameters.tls
        
        // Configure TLS options to capture certificate
        let tlsOptions = parameters.defaultProtocolStack.applicationProtocols.first as? NWProtocolTLS.Options ?? NWProtocolTLS.Options()
        
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { (secProtocolMetadata, secTrust, secProtocolVerifyComplete) in
            // Convert sec_trust_t to SecTrust
            let trust = sec_trust_copy_ref(secTrust).takeRetainedValue()
            
            // Evaluate the trust to ensure it's valid
            var error: CFError?
            let trustResult = SecTrustEvaluateWithError(trust, &error)
            
            if trustResult, error == nil {
                // Get certificate chain
                guard let certificateChain = SecTrustCopyCertificateChain(trust) else {
                    completion(.failure(NSError(domain: "CertificateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get certificate chain"])))
                    secProtocolVerifyComplete(false)
                    return
                }
                
                let certCount = CFArrayGetCount(certificateChain)
                guard certCount > 0 else {
                    completion(.failure(NSError(domain: "CertificateService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty certificate chain"])))
                    secProtocolVerifyComplete(false)
                    return
                }
                
                // Get the first certificate (leaf certificate)
                let cert = CFArrayGetValueAtIndex(certificateChain, 0)
                let certificate = Unmanaged<SecCertificate>.fromOpaque(cert!).takeUnretainedValue()
                
                // Extract certificate information
                let certInfo = self.extractCertificateInfo(from: certificate, host: host)
                completion(.success(certInfo))
                secProtocolVerifyComplete(true)
            } else {
                completion(.failure(error ?? NSError(domain: "CertificateService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to validate certificate chain"])))
                secProtocolVerifyComplete(false)
            }
        }, DispatchQueue.global())
        
        let connection = NWConnection(to: endpoint, using: parameters)
        
        connection.stateUpdateHandler = { (state: NWConnection.State) in
            switch state {
            case .ready:
                // The certificate is handled in the verify block above
                connection.cancel()
            case .failed(let error):
                completion(.failure(error))
                connection.cancel()
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    private func extractCertificateInfo(from certificate: SecCertificate, host: String) -> CertificateInfo {
        // Common Name from subject summary
        let commonName = SecCertificateCopySubjectSummary(certificate) as String? ?? host
        
        // Get certificate values dictionary
        var error: Unmanaged<CFError>?
        let certDict = SecCertificateCopyValues(certificate, nil, &error) as? [String: Any]
        
        // Extract subject information
        var organization = "Unknown"
        var organizationalUnit = "Unknown"
        var country = "Unknown"
        
        if let subjectName = certDict?[kSecOIDX509V1SubjectName as String] as? [String: Any],
           let subjectData = subjectName["value"] as? [[String: Any]] {
            for item in subjectData {
                if let oid = item["oid"] as? String,
                   let values = item["value"] as? [[String: Any]] {
                    for value in values {
                        if let stringValue = value["value"] as? String {
                            if oid == (kSecOIDOrganizationName as String) {
                                organization = stringValue
                            } else if oid == (kSecOIDOrganizationalUnitName as String) {
                                organizationalUnit = stringValue
                            } else if oid == (kSecOIDCountryName as String) {
                                country = stringValue
                            }
                        }
                    }
                }
            }
        }
        
        // Extract validity dates
        var validFrom = Date.distantPast
        var validTo = Date.distantFuture
        
        if let validityNotBefore = certDict?[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
           let notBeforeDate = validityNotBefore["value"] as? Date {
            validFrom = notBeforeDate
        }
        
        if let validityNotAfter = certDict?[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
           let notAfterDate = validityNotAfter["value"] as? Date {
            validTo = notAfterDate
        }
        
        // Extract serial number
        var serialNumber = "Unknown"
        if let serialData = SecCertificateCopySerialNumberData(certificate, nil) {
            let data = serialData as Data
            serialNumber = data.map { String(format: "%02X", $0) }.joined(separator: ":")
        }
        
        // Extract issuer information
        var issuer = "Unknown"
        if let issuerName = certDict?[kSecOIDX509V1IssuerName as String] as? [String: Any],
           let issuerData = issuerName["value"] as? [[String: Any]] {
            for item in issuerData {
                if let oid = item["oid"] as? String,
                   oid == (kSecOIDCommonName as String),
                   let values = item["value"] as? [[String: Any]] {
                    for value in values {
                        if let stringValue = value["value"] as? String {
                            issuer = stringValue
                            break
                        }
                    }
                }
            }
        }
        
        // Calculate fingerprint (SHA-256)
        let certData = SecCertificateCopyData(certificate) as Data
        let digest = certData.sha256()
        let fingerprint = digest.map { String(format: "%02X", $0) }.joined(separator: ":")
        
        // Extract key information
        var keySize = "Unknown"
        var signatureAlgorithm = "Unknown"
        
        if let publicKey = SecCertificateCopyKey(certificate) {
            let attributes = SecKeyCopyAttributes(publicKey) as? [String: Any]
            if let keySizeValue = attributes?[kSecAttrKeySizeInBits as String] as? Int {
                keySize = "\(keySizeValue) bits"
            }
        }
        
        if let sigAlg = certDict?[kSecOIDX509V1SignatureAlgorithm as String] as? [String: Any],
           let algValue = sigAlg["value"] as? String {
            signatureAlgorithm = algValue
        }
        
        return CertificateInfo(
            commonName: commonName,
            organization: organization,
            organizationalUnit: organizationalUnit,
            country: country,
            validFrom: validFrom,
            validTo: validTo,
            serialNumber: serialNumber,
            issuer: issuer,
            fingerprint: fingerprint,
            keySize: keySize,
            signatureAlgorithm: signatureAlgorithm
        )
    }
}

// Extension to compute SHA-256 hash
extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return Data(hash)
    }
}

// MARK: - Certificate Detail View
struct CertificateDetailView: View {
    let certificate: CertificateInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        Image(systemName: certificate.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(certificate.isValid ? .green : .orange)
                            .font(.system(size: 12))
                        
                        Text(certificate.isValid ? "Valid Certificate" : "Certificate Issue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Certificate Information
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    certificateSection("Subject", items: [
                        ("Common Name", certificate.commonName.isEmpty ? "N/A" : certificate.commonName),
                        ("Organization", certificate.organization.isEmpty ? "N/A" : certificate.organization),
                        ("Organizational Unit", certificate.organizationalUnit.isEmpty ? "N/A" : certificate.organizationalUnit),
                        ("Country", certificate.country.isEmpty ? "N/A" : certificate.country)
                    ])
                    
                    certificateSection("Validity", items: [
                        ("Valid From", formatDate(certificate.validFrom)),
                        ("Valid To", formatDate(certificate.validTo)),
                        ("Days Until Expiration", "\(certificate.daysUntilExpiration) days")
                    ])
                    
                    certificateSection("Certificate", items: [
                        ("Serial Number", certificate.serialNumber.isEmpty ? "N/A" : certificate.serialNumber),
                        ("Signature Algorithm", certificate.signatureAlgorithm.isEmpty ? "N/A" : certificate.signatureAlgorithm),
                        ("Key Size", certificate.keySize.isEmpty ? "N/A" : certificate.keySize)
                    ])
                    
                    certificateSection("Issuer", items: [
                        ("Issued By", certificate.issuer.isEmpty ? "N/A" : certificate.issuer)
                    ])
                    
                    certificateSection("Fingerprint", items: [
                        ("SHA-256", certificate.fingerprint.isEmpty ? "N/A" : certificate.fingerprint)
                    ])
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(width: 400, height: 500)
        .background(.regularMaterial)
        .accessibilityLabel("Certificate Details View")
    }
    
    private func certificateSection(_ title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.0) { item in
                    HStack(alignment: .top) {
                        Text(item.0)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .leading)
                        
                        Text(item.1)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.0): \(item.1)")
                }
            }
            .padding(.leading, 8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
