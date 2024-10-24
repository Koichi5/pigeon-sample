////
////  TodoView.swift
////  Runner
////
////  Created by Koichi Kishimoto on 2024/10/21.
////
//
//import SwiftUI
//import WatchConnectivity
//
//struct TodoView: View {
//    @State private var title: String = ""
//    @State private var description: String = ""
//    @State private var session = WCSession.default
//    private var sessionDelegate = TodoWatchSessionDelegate()
//    
//    var body: some View {
//        VStack {
//            TextField("Title", text: $title)
//                .padding()
//            TextField("Description", text: $description)
//                .padding()
//            Spacer()
//            Button("Add") {
//                sendAddTodo(
//                    title: title,
//                    description: description
//                )
//            }
//        }
//        .onAppear {
//            setupSession()
//        }
//    }
//    
//    func setupSession() {
//        if WCSession.isSupported() {
//            session.delegate = sessionDelegate
//            session.activate()
//        }
//    }
//    
//    func sendAddTodo(title: String, description: String) {
//        let message = [
//            "action": "addTodo",
//            "title": title,
//            "description": description
//        ] as [String : Any]
//        
//        session.sendMessage(message, replyHandler: nil) { error in
//            print("Error sending add todo message: \(error.localizedDescription)")
//        }
//    }
//    
//    func sendDeleteTodo(todoId: String) {
//        let message = [
//            "action": "deleteTodo",
//            "id": todoId,
//            "title": title,
//            "description": description
//        ] as [String : Any]
//        
//        session.sendMessage(message, replyHandler: nil) { error in
//            print("Error sending delete todo message: \(error.localizedDescription)")
//        }
//    }
//}

import SwiftUI
import WatchConnectivity

struct TodoListView: View {
    @ObservedObject var sessionDelegate = TodoWatchSessionDelegate()
    @State private var session = WCSession.default
    
    var body: some View {
        List(sessionDelegate.todos) { todo in
            VStack(alignment: .leading) {
                Text(todo.title)
                    .font(.headline)
                Text(todo.description)
                    .font(.subheadline)
                if todo.isDone {
                    Text("Done")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Not Done")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            setupSession()
        }
    }
    
    func setupSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = sessionDelegate
            session.activate()
        }
    }
    
    func requestTodos() {
        let message = ["action": "fetchTodos"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error requesting todos: \(error.localizedDescription)")
        }
    }
}
