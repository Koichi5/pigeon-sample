//
//  Record.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import Foundation

struct Record: Identifiable {
    var id: String
    var book: Book
    var seconds: Int64
    var createdAt: Int64
    var lastModified: Int64

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let bookData = dictionary["book"] as? [String: Any],
              let book = Book(dictionary: bookData),
              let seconds = dictionary["seconds"] as? Int64,
              let createdAt = dictionary["createdAt"] as? Int64,
              let lastModified = dictionary["lastModified"] as? Int64 else {
            return nil
        }

        self.id = id
        self.book = book
        self.seconds = seconds
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}
