//
//  BookAppDelegate.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/21.
//

import Flutter
import WatchConnectivity
import UIKit

@main
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
    
    func fetchBooks(completion: @escaping ([Book]) -> Void) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            completion([])
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.fetchBooks { result in
                switch result {
                case .success(let books):
                    print("Successfully fetched books from Flutter.")
                    print("Fetched Books: \(books)")
                    completion(books)
                case .failure(let error):
                    print("Error calling Flutter fetchBooks method: \(error.localizedDescription)")
                    completion([])
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
    
    func fetchRecords(completion: @escaping ([Record]) -> Void) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            completion([])
            return
        }
        
        DispatchQueue.main.async {
            let api = BookFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.fetchRecords() { result in
                switch result {
                case .success(let records):
                    print("Successfully fetched records from Flutter.")
                    print("Fetched Records: \(records)")
                    completion(records)
                case .failure(let error):
                    print("Error calling Flutter fetchRecords method: \(error.localizedDescription)")
                    completion([])
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
                print("Record in addRecord(iOS): \(record)")
                switch result {
                case .success():
                    print("Successfully called Flutter addRecord method.")
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
}
