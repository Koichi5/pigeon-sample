//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/22.
//

import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()
    private override init() {
        super.init()
        setupWCSession()
    }
    
    @Published var books: [Book] = []
    @Published var records: [Record] = []
    
    private var session: WCSession {
        return WCSession.default
    }
    
    private func setupWCSession() {
        print("setupWCSession fired")
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func requestBooks() {
        print("request books fired")
        if session.isReachable {
            let message = ["action": "fetchBooks"]
            session.sendMessage(message, replyHandler: { response in
                if let booksData = response["books"] as? [[String: Any]] {
                    let receivedBooks = booksData.compactMap { Book(dictionary: $0) }
                    DispatchQueue.main.async {
                        self.books = receivedBooks
                        print("Updated books: \(self.books)")
                    }
                } else {
                    print("No books found in response.")
                }
            }, errorHandler: { error in
                print("Error requesting books: \(error.localizedDescription)")
            })
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func requestRecords() {
        print("request records fired")
        if session.isReachable {
            let message = ["action": "fetchRecords"]
            session.sendMessage(message, replyHandler: { response in
                if let recordsData = response["records"] as? [[String: Any]] {
                    print("recordsData: \(recordsData)")
                    let receivedRecords = recordsData.compactMap { Record(dictionary: $0) }
                    DispatchQueue.main.async {
                        self.records = receivedRecords
                        print("Updated records: \(self.records)")
                    }
                } else {
                    print("No records found in response")
                }
            }, errorHandler: { error in
                print("Error requesting records: \(error.localizedDescription)")
            })
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func incrementTimer(count: Int) {
        print("increment timer fired")
        if session.isReachable {
            let message: [String: Any] = [
                "action": "incrementTimer",
                "count": count
            ]
            session.sendMessage(message, replyHandler: { response in
                if let countData = response["count"] as? Int {
                    print("count: \(countData)")
                } else {
                    print("No count found in response")
                }
            }, errorHandler: { error in
                print("Error requesting records: \(error.localizedDescription)")
            })
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func addRecord(book: Book, seconds: Int) {
        print("add record fired")
        print("add record book: \(book)")
        if session.isReachable {
            let message: [String: Any] = [
                "action": "addRecord",
                "book": [
                    "id": book.id,
                    "title": book.title,
                    "publisher": book.publisher,
                    "imageUrl": book.imageUrl,
                    "lastModified": book.lastModified
                ],
                "seconds": seconds,
                "createdAt": Int(Date().timeIntervalSince1970),
                "lastModified": Int(Date().timeIntervalSince1970)
            ]
            
            session.sendMessage(message, replyHandler: { response in
                // iOS 側から保存の完了状態を受け取る
                if let status = response["status"] as? [[String: Any]] {
                    print(status)
                }
            })
        }
    }
    
    // MARK: - WCSessionDelegate メソッド
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    // message を使用
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // requestBooks を watchOS から実行 → iOS が検知して Flutter 側の処理を実行 → 取得した本のデータを watchOS 側に送信 → ここで受け取る
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "fetchedBooks":
                    print("watchOS: Received fetchedBooks action")
                    if let booksData = message["books"] as? [[String: Any]] {
                        let receivedBooks = booksData.compactMap { Book(dictionary: $0) }
                        self.books = receivedBooks
                        print("Updated books: \(self.books)")
                    }
                case "fetchedRecords":
                    print("watchOS: Received fetchedRecords action")
                    if let recordsData = message["records"] as? [[String: Any]] {
                        let receivedRecords = recordsData.compactMap { Record(dictionary: $0) }
                        self.records = receivedRecords
                        print("Updated records: \(self.records)")
                    }
                default:
                    break
                }
            }
        }
    }
    
    // applicationContext を使用
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let action = applicationContext["action"] as? String {
                switch action {
                case "fetchedBooks":
                    print("Received fetchedBooks action via applicationContext")
                    if let booksData = applicationContext["books"] as? [[String: Any]] {
                        let receivedBooks = booksData.compactMap { Book(dictionary: $0) }
                        self.books = receivedBooks
                        print("Updated books: \(self.books)")
                    }
                default:
                    break
                }
            }
        }
    }
    
    // 他の必要なデリゲートメソッドを実装
    func sessionReachabilityDidChange(_ session: WCSession) {
        // セッションの到達可能性が変化したときの処理
    }
}
