//
//  BookView.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

// watchOS アプリ側 - BookListView.swift

import SwiftUI

struct BookListView: View {
    @ObservedObject var sessionManager = WCSessionManager.shared

    var body: some View {
        List(sessionManager.books) { book in
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                Text(book.publisher)
                    .font(.subheadline)
            }
        }
    }
}
