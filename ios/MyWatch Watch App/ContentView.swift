//
//  ContentView.swift
//  MyWatch Watch App
//
//  Created by Koichi Kishimoto on 2024/10/20.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var batteryLevel: Float = 0.0
    @State private var session = WCSession.default
    private var sessionDelegate = WatchSessionDelegate()

    var body: some View {
        VStack {
            Text("Battery Level: \(Int(batteryLevel * 100))%")
                .padding()

            Button(action: {
                sendBatteryLevel()
            }) {
                Text("Send Battery Level")
            }
        }
        .onAppear {
            setupSession()
            updateBatteryLevel()
        }
    }

    func setupSession() {
        if WCSession.isSupported() {
            session.delegate = sessionDelegate // デリゲートを設定
            session.activate()
        }
    }

    func updateBatteryLevel() {
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        batteryLevel = device.batteryLevel
    }

    func sendBatteryLevel() {
        updateBatteryLevel()
        let message = [
            "action": "saveData",
            "batteryLevel": batteryLevel * 100 // パーセンテージに変換
        ] as [String : Any]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    // 他のデリゲートメソッドを必要に応じて実装
}
