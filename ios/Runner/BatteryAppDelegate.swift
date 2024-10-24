//
//  BatteryAppDelegate.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/10/23.
//

import Flutter
import WatchConnectivity
import UIKit

//@main
@objc class BatteryAppDelegate: FlutterAppDelegate, WCSessionDelegate {
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
        
        // BatteryHostApiのセットアップ
        let batteryApi = BatteryHostApiImpl(binaryMessenger: flutterEngine!.binaryMessenger)
        BatteryHostApiSetup.setUp(binaryMessenger: flutterEngine!.binaryMessenger, api: batteryApi)
        
        // Watch Connectivityのセットアップ
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
//    func triggerFlutterSave(batteryLevel: Float, source: String) {
//        guard let flutterEngine = flutterEngine else {
//            print("FlutterEngine is not available.")
//            return
//        }
//
//        let api = SaveDataFlutterApi(binaryMessenger: flutterEngine.binaryMessenger)
//        api.triggerSave(batteryLevel: Double(batteryLevel), source: source) { result in
//            switch result {
//            case .success():
//                print("Successfully called Flutter method.")
//            case .failure(let error):
//                print("Error calling Flutter method: \(error.localizedDescription)")
//            }
//        }
//    }
    
    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activation did complete with state: \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("session did receive message: \(message)")
        if let action = message["action"] as? String, action == "saveData" {
            // バッテリーレベルを取得
            let batteryLevel = message["batteryLevel"] as? Float ?? 0.0

            // Flutter側のメソッドを呼び出す
//            triggerFlutterSave(batteryLevel: batteryLevel, source: "watchOS")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivate")
    }
}
