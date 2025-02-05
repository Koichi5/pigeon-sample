//
//  Untitled.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import SwiftUI

struct RecordListView: View {
    @ObservedObject var sessionManager = WCSessionManager.shared
    
    var body: some View {
        NavigationStack {
            if(sessionManager.records.isEmpty) {
                Button(action: {
                    sessionManager.fetchRecords()
                }, label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                })
            }
            List(sessionManager.records) { record in
                RecordRow(record: record)
            }
            .refreshable {
                print("refresh records fired")
                sessionManager.fetchRecords()
            }
            .navigationTitle("Record")
        }
    }
}

struct RecordRow: View {
    let record: Record
    
    var body: some View {
        let imageUrl = URL(string: record.book.imageUrl)
        HStack {
            AsyncImage(url: imageUrl) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "book.closed.fill")
            }
            .frame(width: 30, height: 45)
            .cornerRadius(5)
            VStack(alignment: .leading, spacing: 8) {
                Text(record.book.title)
                    .font(.headline)
            }
            Spacer()
            Text(formatTime(seconds: Int(record.seconds)))
                .font(.title3)
                .fontWeight(.bold)
        }
    }
    private func formatTime(seconds totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var components = [String]()
        
        if hours > 0 {
            components.append("\(hours)")
        }
        
        if minutes > 0 {
            // hoursが0の場合はゼロ埋めしない
            let minuteString = hours > 0 ? String(format: "%02d", minutes) : "\(minutes)"
            components.append(minuteString)
        }
        
        if seconds > 0 {
            // hoursまたはminutesが0より大きい場合はゼロ埋め
            let secondString = (hours > 0 || minutes > 0) ? String(format: "%02d", seconds) : "\(seconds)"
            components.append(secondString)
        }
        
        // すべての値が0の場合は"0"を返す
        if components.isEmpty {
            return "0"
        } else {
            return components.joined(separator: " : ")
        }
    }
}
