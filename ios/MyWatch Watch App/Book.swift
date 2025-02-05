//
//  Book.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import Foundation

struct Book: Identifiable {
    var id: String
    var title: String
    var publisher: String
    var imageUrl: String
    var lastModified: Int64

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let publisher = dictionary["publisher"] as? String,
              let imageUrl = dictionary["imageUrl"] as? String,
              let lastModifiedValue = dictionary["lastModified"] as? Int64 else {
            print("Failed to parse Book from dictionary: \(dictionary)")
            return nil
        }

        self.id = id
        self.title = title
        self.publisher = publisher
        self.imageUrl = imageUrl
        self.lastModified = lastModifiedValue
    }
}
