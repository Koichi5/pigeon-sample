//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context: \(applicationContext)")
        // 既存の処理
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivater")
    }
    
    static let shared = WCSessionManager()
    private override init() {
        super.init()
        setupWCSession()
    }
    
    private var session: WCSession {
        return WCSession.default
    }
    
    private func setupWCSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let action = message["action"] as? String {
            switch action {
            case "addBook":
                let title = message["title"] as? String ?? "None"
                let publisher = message["publisher"] as? String ?? "None"
                let imageUrl = message["imageUrl"] as? String ?? "None"
                let lastModified = message["lastModified"] as? Int ?? 0
                
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.addBook(book: Book(
                        title: title,
                        publisher: publisher,
                        imageUrl: imageUrl,
                        lastModified: Int64(lastModified)
                    ))
                }
                
            case "deleteBook":
                let id = message["id"] as? String ?? "None"
                let title = message["title"] as? String ?? "None"
                let publisher = message["publisher"] as? String ?? "None"
                let imageUrl = message["imageUrl"] as? String ?? "None"
                let lastModified = message["lastModified"] as? Int ?? 0
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.deleteBook(book: Book(
                        id: id,
                        title: title,
                        publisher: publisher,
                        imageUrl: imageUrl,
                        lastModified: Int64(lastModified)
                    ))
                }
                
            case "fetchBooks":
                print("iOS: Received fetchedBooks action")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.fetchBooks()
                }
                
            case "addRecord":
                let book = message["book"] as? Book ?? Book(title: "title", publisher: "publisher", imageUrl: "imageUrl", lastModified: 0)
                let seconds = message["seconds"] as? Int ?? 0
                let createdAt = message["createdAt"] as? Int ?? 0
                let lastModified = message["lastModified"] as? Int ?? 0
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.addRecord(record: Record(
                        book: book,
                        seconds: Int64(seconds),
                        createdAt: Int64(createdAt),
                        lastModified: Int64(lastModified)
                    ))
                }
            case "deleteRecord":
                let book = message["book"] as? Book ?? Book(id: "id", title: "title", publisher: "publisher", imageUrl: "imageUrl", lastModified: 0)
                let seconds = message["seconds"] as? Int ?? 0
                let createdAt = message["createdAt"] as? Int ?? 0
                let lastModified = message["lastModified"] as? Int ?? 0
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.deleteRecord(record: Record(
                        book: book,
                        seconds: Int64(seconds),
                        createdAt: Int64(createdAt),
                        lastModified: Int64(lastModified)
                    ))
                }
                
            case "fetchRecords":
                print("iOS: Received fetchRecords action")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.fetchRecords()
                }
            default:
                print("Unknown action: \(message)")
            }
        }
    }
    
    func sendBooksToWatch(booksData: [[String: Any]]) {
        let message: [String: Any] = ["action": "fetchedBooks", "books": booksData]
        if session.activationState == .activated {
            do {
                try session.updateApplicationContext(message)
                print("Sent books data using updateApplicationContext.")
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not activated yet.")
        }
    }
}


