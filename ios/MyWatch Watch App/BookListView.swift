//
//  BookView.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import SwiftUI

struct BookListView: View {
    @ObservedObject var sessionManager = WCSessionManager.shared

    var body: some View {
        NavigationStack {
            if (sessionManager.books.isEmpty) {
                Button(action: {
                    sessionManager.requestBooks()
                }, label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                })
            }
            List(sessionManager.books) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRow(book: book)
                }
            }
            .refreshable {
                print("refresh books fired")
                sessionManager.requestBooks()
            }
            .navigationTitle("Books")
        }
    }
}

struct BookRow: View {
    let book: Book
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: book.imageUrl)) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "book.closed.fill")
            }
            .frame(width: 30, height: 45)
            .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                Text(book.publisher)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            .padding()
        }
    }
}
