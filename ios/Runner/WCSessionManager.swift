//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = WCSessionManager()
    
    private override init() {
        super.init()
        setupWCSession()
    }
    
    private var session: WCSession {
        return WCSession.default
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivater")
    }
    
    private func setupWCSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        if let action = message["action"] as? String {
            switch action {
            case "fetchBooks":
                print("iOS: Received fetchBooks action")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.fetchBooks { books in
                        // データ取得後にreplyHandlerで結果を返す
                        let booksData = books.map { book in
                            return [
                                "id": book.id ?? "",
                                "title": book.title,
                                "publisher": book.publisher,
                                "imageUrl": book.imageUrl,
                                "lastModified": book.lastModified
                            ]
                        }
                        replyHandler(["books": booksData])
                    }
                }
                
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
                replyHandler(["reply" : "OK"])

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
                replyHandler(["reply" : "OK"])

            case "fetchRecords":
                print("iOS: Received fetchRecords action")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? BookAppDelegate)?.fetchRecords() { records in
                        let recordsData = records.map { record in
                            return [
                                "id": record.id ?? "",
                                "book": [
                                    "id": record.book.id ?? "",
                                    "title": record.book.title,
                                    "publisher": record.book.publisher,
                                    "imageUrl": record.book.imageUrl,
                                    "lastModified": record.book.lastModified
                                ],
                                "seconds": record.seconds,
                                "createdAt": record.createdAt,
                                "lastModified": record.lastModified
                            ]
                        }
                        replyHandler(["records": recordsData])
                    }
                }
                
            case "addRecord":
                if let bookDict = message["book"] as? [String: Any] {
                    let book = Book(
                        id: bookDict["id"] as? String ?? "",
                        title: bookDict["title"] as? String ?? "",
                        publisher: bookDict["publisher"] as? String ?? "",
                        imageUrl: bookDict["imageUrl"] as? String ?? "",
                        lastModified: bookDict["lastModified"] as? Int64 ?? 0
                    )
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
                        replyHandler(["status": "success"])
                    }
                } else {
                    print("Error: Invalid book data")
                    replyHandler(["status": "failure", "error": "Invalid book data"])
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
                replyHandler(["reply" : "OK"])
            
//            case "startTimer":
//                let count = message["count"] as? Int ?? 0
//                DispatchQueue.main.async {
//                    (UIApplication.shared.delete as? BookAppDelegate)?.startTimer(count: Int64(count))
//                }
//                replyHandler(["count": count])
                
            default:
                print("Unknown action: \(message)")
                replyHandler(["reply" : "OK"])
            }
        }
    }
    
//    func sendBooksToWatch(booksData: [[String: Any]]) {
//        let message: [String: Any] = ["action": "fetchedBooks", "books": booksData]
//        if session.isReachable {
//            session.sendMessage(message, replyHandler: nil) { error in
//                print("Error sending books data: \(error.localizedDescription)")
//            }
//            print("Sent books data using sendMessage.")
//        } else {
//            print("WCSession is not reachable.")
//        }
//    }
}


