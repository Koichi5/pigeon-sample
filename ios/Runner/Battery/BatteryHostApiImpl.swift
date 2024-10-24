 //
 //  BatteryLevelApi.swift
 //  Runner
 //
 //  Created by Koichi Kishimoto on 2024/10/20.
 //

 import Foundation

 enum BatteryError: Error {
     case unavailable
 }

class BatteryHostApiImpl: BatteryHostApi {
    private let flutterApi: BatteryFlutterApi
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = BatteryFlutterApi(binaryMessenger: binaryMessenger)
    }
    
    func getBatteryInfo() throws -> BatteryInfo {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        // Battery Level
        let batteryLevel = Int64(device.batteryLevel * 100)
        
        // Battery Status
        let batteryStatus: UIDevice.BatteryState = device.batteryState
        var batteryStatusLabel = ""
        switch batteryStatus {
        case .unknown:
            batteryStatusLabel = "Unknown 🤔"
        case .unplugged:
            batteryStatusLabel = "Unplugged 🔌"
        case .charging:
            batteryStatusLabel = "Charging ⚡"
        case .full:
            batteryStatusLabel = "Full 🔋"
        @unknown default:
            batteryStatusLabel = "Unknown 🤔"
        }
        device.isBatteryMonitoringEnabled = false

        let batteryInfo = BatteryInfo(batteryLevel: batteryLevel, batteryStatus: batteryStatusLabel, source: "iOS")
        flutterApi.onBatteryInfoReceived(batteryInfo: batteryInfo) { result in
            switch result {
            case .success():
                print("Successfully sent battery info to Flutter")
            case .failure(let error):
                print("Error sending battery info to Flutter: \(error.localizedDescription)")
            }
        }
        
        return batteryInfo
    }
}
