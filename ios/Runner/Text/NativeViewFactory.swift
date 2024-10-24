// //
// //  NativeViewFactory.swift
// //  Runner
// //
// //  Created by Koichi Kishimoto on 2024/10/20.
// //

// import Foundation
// import Flutter
// import UIKit

// class NativeViewFactory: NSObject, FlutterPlatformViewFactory {
//     private var messenger: FlutterBinaryMessenger

//     init(messenger: FlutterBinaryMessenger) {
//         self.messenger = messenger
//         super.init()
//     }

//     func create(
//         withFrame frame: CGRect,
//         viewIdentifier viewId: Int64,
//         arguments args: Any?
//     ) -> FlutterPlatformView {
//         return NativeView(
//             frame: frame,
//             viewIdentifier: viewId,
//             arguments: args,
//             binaryMessenger: messenger)
//     }
// }
