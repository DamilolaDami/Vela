import Foundation
import WebKit
import Combine

@Observable
class SchemaDetectionService {
    var detectedSchemas: [DetectedSchema] = []
    
    func scanSchemas(in webView: WKWebView) {
      
        let js = """
        (function() {
            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            const schemas = [];
            scripts.forEach(script => {
                try {
                    const parsed = JSON.parse(script.innerText);
                    if (Array.isArray(parsed)) {
                        parsed.forEach(p => schemas.push(p));
                    } else {
                        schemas.push(parsed);
                    }
                } catch {}
            });
            return JSON.stringify(schemas);
        })();
        """
        
        webView.evaluateJavaScript(js) { [weak self] result, error in
            guard let self = self else { return }
            guard let json = result as? String,
                  let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("⚠️ Failed to parse schema.org JSON-LD")
                return
            }
            self.handleParsedSchemas(parsed)
        }
    }
    
    private func handleParsedSchemas(_ schemas: [[String: Any]]) {
        let mapped: [DetectedSchema] = schemas.compactMap { dict in
            // Handle @type as either String or Array
            let typeValue = dict["@type"]
            let typeString: String
            
            if let typeArray = typeValue as? [String], let firstType = typeArray.first {
                // If @type is an array, take the first type
                typeString = firstType.lowercased()
            } else if let singleType = typeValue as? String {
                // If @type is a string, use it directly
                typeString = singleType.lowercased()
            } else {
                // Fallback for unexpected types
                typeString = "unknown"
            }
            
            let type = DetectedSchemaType(rawValue: typeString) ?? .unknown
            
            // Skip unknown schema types
            guard type != .unknown else {
                print("⚠️ Skipping unknown schema type: \(typeString)")
                return nil
            }
            
            let title = dict["name"] as? String ?? dict["headline"] as? String
            let description = dict["description"] as? String
            let imageURL = extractImageURL(from: dict)
            
            return DetectedSchema(
                type: type,
                title: title,
                description: description,
                imageURL: imageURL,
                rawData: dict
            )
        }
        
        DispatchQueue.main.async {
            self.detectedSchemas = mapped
        }
    }
    
    private func extractImageURL(from dict: [String: Any]) -> String? {
        // Handle different image field formats in schema.org
        
        // 1. Direct image URL as string
        if let imageString = dict["image"] as? String {
            return imageString
        }
        
        // 2. Image as array of strings (take first)
        if let imageArray = dict["image"] as? [String], let firstImage = imageArray.first {
            return firstImage
        }
        
        // 3. Image as object with url property
        if let imageObject = dict["image"] as? [String: Any] {
            if let url = imageObject["url"] as? String {
                return url
            }
            // Sometimes the object itself contains the URL directly
            if let url = imageObject["@id"] as? String {
                return url
            }
        }
        
        // 4. Image as array of objects (take first object's url)
        if let imageArray = dict["image"] as? [[String: Any]],
           let firstImage = imageArray.first,
           let url = firstImage["url"] as? String {
            return url
        }
        
        // 5. Check for thumbnail property as fallback
        if let thumbnail = dict["thumbnail"] as? String {
            return thumbnail
        }
        
        // 6. Check for thumbnailUrl property
        if let thumbnailUrl = dict["thumbnailUrl"] as? String {
            return thumbnailUrl
        }
        
        return nil
    }
}
