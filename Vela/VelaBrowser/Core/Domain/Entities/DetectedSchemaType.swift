//
//  DetectedSchemaType.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//


import Foundation

enum DetectedSchemaType: String {
    case recipe = "recipe"
    case product = "product"
    case event = "event"
    case article = "article"
    case unknown = "unknown"
    case newsArticle = "newsarticle"  // Match the lowercased version
}

struct DetectedSchema: Identifiable {
    let id = UUID()
    let type: DetectedSchemaType
    let title: String?
    let description: String?
    let imageURL: String?
    let rawData: [String: Any]
}
