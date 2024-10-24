//
//  TodoAppDelegate.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/21.
//

import Flutter
import WatchConnectivity
import UIKit

//@main
@objc class TodoAppDelegate: FlutterAppDelegate, WCSessionDelegate {
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
        
        // Watch Connectivityのセットアップ
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    func addTodo(todo: Todo) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = TodoFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.addTodo(todo: todo) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter addTodo method.")
                case .failure(let error):
                    print("Error calling Flutter addTodo method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteTodo(todo: Todo) {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = TodoFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.deleteTodo(todo: todo) { result in
                switch result {
                case .success():
                    print("Successfully called Flutter deleteTodo method.")
                case .failure(let error):
                    print("Error calling Flutter deleteTodo method: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchTodos() {
        guard let flutterEngine = flutterEngine else {
            print("Flutter Engine is not available.")
            return
        }
        
        DispatchQueue.main.async {
            let api = TodoFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
            api.fetchTodos { result in
                switch result {
                case .success(let todos):
                    print("Successfully fetched todos from Flutter.")
                    // 取得した Todo のリストを処理
                    self.handleFetchedTodos(todos)
                case .failure(let error):
                    print("Error fetching todos from Flutter: \(error.localizedDescription)")
                }
            }
        }
    }

    // 取得した Todo のリストを処理するメソッド
    func handleFetchedTodos(_ todos: [Todo?]) {
        let todosData = todos.compactMap { todo -> [String: Any]? in
            guard let todo = todo else { return nil }
            return [
                "id": todo.id,
                "title": todo.title,
                "description": todo.description,
                "isDone": todo.isDone
            ]
        }
        sendTodosToWatch(todosData: todosData)
    }

    // watchOS アプリにデータを送信するメソッド
    func sendTodosToWatch(todosData: [[String: Any]]) {
        let message: [String: Any] = ["action": "fetchedTodos", "todos": todosData]
        do {
            try WCSession.default.updateApplicationContext(message)
            print("Sent todos data using updateApplicationContext.")
        } catch {
            print("Error updating application context: \(error.localizedDescription)")
        }
    }

    
    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activation did complete with state: \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("session did receive message: \(message)")
        if let action = message["action"] as? String {
            switch action {
            case "addTodo":
                let title = message["title"] as? String ?? "None"
                let description = message["description"] as? String ?? "None"
                
                addTodo(todo: Todo(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    isDone: false)
                )
            case "deleteTodo":
                let id = message["id"] as? String ?? "None"
                let title = message["title"] as? String ?? "None"
                let description = message["description"] as? String ?? "None"
                
                deleteTodo(todo: Todo(
                    id: id,
                    title: title,
                    description: description,
                    isDone: false)
                )
            case "fetchTodos":
                fetchTodos()
            default:
                break
            }
        }
    }

    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivate")
    }
}
