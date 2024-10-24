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
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error requesting books: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func requestRecords() {
        print("request records fired")
        if session.isReachable {
            let message = ["action": "fetchRecords"]
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error requesting records: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable.")
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
