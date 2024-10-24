//
//  TOdoWatchSessionDelegate.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/23.
//

import WatchConnectivity

class TodoWatchSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    @Published var todos: [Todo] = []
    
    var session: WCSession {
        return WCSession.default
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activated with state: \(activationState.rawValue)")

        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else if activationState == .activated {
            // セッションがアクティブになったので、メッセージを送信
            requestTodos()
        }
    }
    
    // メッセージの送信
    func requestTodos() {
        let message = ["action": "fetchTodos"]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error requesting todos: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable.")
        }
    }

    // データ受信時に呼ばれるメソッド
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context: \(applicationContext)")
        DispatchQueue.main.async {
            if let action = applicationContext["action"] as? String, action == "fetchedTodos" {
                if let todosData = applicationContext["todos"] as? [[String: Any]] {
                    let receivedTodos = todosData.compactMap { dict -> Todo? in
                        return Todo(dictionary: dict)
                    }
                    self.todos = receivedTodos
                }
            }
        }
    }
    
    // 必要に応じて他のデリゲートメソッドを実装
}
