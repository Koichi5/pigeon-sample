//
//  Todo.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/23.
//

struct Todo: Identifiable {
    var id: String
    var title: String
    var description: String
    var isDone: Bool
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let description = dictionary["description"] as? String,
              let isDone = dictionary["isDone"] as? Bool else {
            return nil
        }
        self.id = id
        self.title = title
        self.description = description
        self.isDone = isDone
    }
}
