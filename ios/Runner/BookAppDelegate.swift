//
//  BookAppDelegate.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/21.
//

import Flutter
import WatchConnectivity
import UIKit

//@main
@objc class BookAppDelegate: FlutterAppDelegate {
    var flutterEngine: FlutterEngine?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // FlutterEngineを初期化
        flutterEngine = FlutterEngine(name: "MyFlutterEngine")
        flutterEngine?.run()
        
        GeneratedPluginRegistrant.register(with: flutterEngine!)
        
        // FlutterViewControllerをflutterEngineを使用して初期化
        let flutterViewController = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)
        
        // windowを設定し、rootViewControllerにFlutterViewControllerを設定
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = flutterViewController
        self.window?.makeKeyAndVisible()
        
        _ = WCSessionManager.shared
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func fetchBooks() {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.fetchBooks() { result in
                switch result {
                case .success(let books):
                    print("Successfully fetched books from Flutter.")
                    // 取得した本のリストを処理
                    self.handleFetchedBooks(books)
                case .failure(let error):
                    print("Error calling Flutter fetchBooks method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addBook(book: Book) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.addBook(book: book) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter addBook method.")
                case .failure(let error):
                    print("Error calling Flutter addBook method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteBook(book: Book) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.deleteBook(book: book) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter deleteBook method.")
                case .failure(let error):
                    print("Error calling Flutter deleteBook method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 取得した本のリストを処理するメソッド
    func handleFetchedBooks(_ books: [Book]) {
        // 例: 本のデータをwatchOSアプリに送信
        let booksData = books.map { book -> [String: Any] in
            return [
                "id": book.id ?? "",
                "title": book.title,
                "publisher": book.publisher,
                "imageUrl": book.imageUrl,
                "lastModified": book.lastModified
            ]
        }
        WCSessionManager.shared.sendBooksToWatch(booksData: booksData)
    }
    
    
    func fetchRecords() {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.fetchRecords() { result in
                switch result {
                case .success(let records):
                    print("Successfully fetched records from Flutter.")
                    // 取得した記録のリストを処理
                    self.handleFetchedRecords(records)
                case .failure(let error):
                    print("Error calling Flutter fetchRecords method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addRecord(record: Record) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.addRecord(record: record) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter addBook method.")
                case .failure(let error):
                    print("Error calling Flutter addBook method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteRecord(record: Record) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.deleteRecord(record: record) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter deleteBook method.")
                case .failure(let error):
                    print("Error calling Flutter deleteBook method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 取得した記録のリストを処理するメソッド
    func handleFetchedRecords(_ records: [Record]) {
        // 例: 記録のデータをwatchOSアプリに送信
        let recordsData = records.map { record -> [String: Any] in
            let book = record.book
            let bookData: [String: Any] = [
                "id": book.id ?? "",
                "title": book.title,
                "publisher": book.publisher,
                "imageUrl": book.imageUrl,
                "lastModified": book.lastModified
            ]
            
            return [
                "id": record.id ?? "",
                "book": bookData,
                "seconds": record.seconds,
                "createdAt": record.createdAt,
                "lastModified": record.lastModified
            ]
        }
        
        let message: [String: Any] = ["action": "fetchedRecords", "records": recordsData]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending records to watchOS: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable.")
        }
    }
}
