//
//  BookDetailView.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/11/03.
//

import SwiftUI

struct BookDetailView: View {
    let book: Book
    @ObservedObject var sessionManager = WCSessionManager.shared
    
    @State private var seconds: Int = 0
    @State private var isStudying: Bool = false
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                HStack {
                    AsyncImage(url: URL(string: book.imageUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(
                        width: geometry.size.width * 0.2,
                        height: geometry.size.width * 0.2 * 1.5
                    )
                    .cornerRadius(5)
                    
                    Text(book.title)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                
                Text(formatTime(seconds: seconds))
                    .font(.title2)
                    .bold()
                
                HStack {
                    Button(action: {
                        isStudying.toggle()
                        if isStudying {
                            startTimer()
                        } else {
                            stopTimer()
                        }
                    }) {
                        Text(isStudying ? "Stop" : "Start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StudyButtonStyle(isStudying: isStudying))
                    
                    Button(action: {
                        saveRecord()
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaveButtonStyle(isDisabled: seconds == 0))
                    .disabled(seconds == 0)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Studying")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            seconds += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveRecord() {
        sessionManager.addRecord(book: book, seconds: seconds)
        stopTimer()
        seconds = 0
        isStudying = false
    }
    
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StudyButtonStyle: ButtonStyle {
    var isStudying: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(isStudying ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SaveButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(isDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}
