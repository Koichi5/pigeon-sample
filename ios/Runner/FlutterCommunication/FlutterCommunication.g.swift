////
////  FlutterCommunication.g.swift
////  Runner
////
////  Created by Koichi Kishimoto on 2024/10/20.
////
//
//// Autogenerated from Pigeon (v22.5.0), do not edit directly.
//// See also: https://pub.dev/packages/pigeon
//
//import Foundation
//
//#if os(iOS)
//  import Flutter
//#elseif os(macOS)
//  import FlutterMacOS
//#else
//  #error("Unsupported platform.")
//#endif
//
///// Error class for passing custom error details to Dart side.
//final class PigeonError: Error {
//  let code: String
//  let message: String?
//  let details: Any?
//
//  init(code: String, message: String?, details: Any?) {
//    self.code = code
//    self.message = message
//    self.details = details
//  }
//
//  var localizedDescription: String {
//    return
//      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
//      }
//}
//
//private func createConnectionError(withChannelName channelName: String) -> PigeonError {
//  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
//}
//
//private func isNullish(_ value: Any?) -> Bool {
//  return value is NSNull || value == nil
//}
//
//private func nilOrValue<T>(_ value: Any?) -> T? {
//  if value is NSNull { return nil }
//  return value as! T?
//}
//
//private class FlutterCommunicationPigeonCodecReader: FlutterStandardReader {
//}
//
//private class FlutterCommunicationPigeonCodecWriter: FlutterStandardWriter {
//}
//
//private class FlutterCommunicationPigeonCodecReaderWriter: FlutterStandardReaderWriter {
//  override func reader(with data: Data) -> FlutterStandardReader {
//    return FlutterCommunicationPigeonCodecReader(data: data)
//  }
//
//  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
//    return FlutterCommunicationPigeonCodecWriter(data: data)
//  }
//}
//
//class FlutterCommunicationPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
//  static let shared = FlutterCommunicationPigeonCodec(readerWriter: FlutterCommunicationPigeonCodecReaderWriter())
//}
//
///// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
//protocol FlutterCommunicationApiProtocol {
//  func triggerSave(completion: @escaping (Result<Void, PigeonError>) -> Void)
//}
//class FlutterCommunicationApi: FlutterCommunicationApiProtocol {
//  private let binaryMessenger: FlutterBinaryMessenger
//  private let messageChannelSuffix: String
//  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
//    self.binaryMessenger = binaryMessenger
//    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
//  }
//  var codec: FlutterCommunicationPigeonCodec {
//    return FlutterCommunicationPigeonCodec.shared
//  }
//  func triggerSave(completion: @escaping (Result<Void, PigeonError>) -> Void) {
//    let channelName: String = "dev.flutter.pigeon.pigeon_sample.FlutterCommunicationApi.triggerSave\(messageChannelSuffix)"
//    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
//    channel.sendMessage(nil) { response in
//      guard let listResponse = response as? [Any?] else {
//        completion(.failure(createConnectionError(withChannelName: channelName)))
//        return
//      }
//      if listResponse.count > 1 {
//        let code: String = listResponse[0] as! String
//        let message: String? = nilOrValue(listResponse[1])
//        let details: String? = nilOrValue(listResponse[2])
//        completion(.failure(PigeonError(code: code, message: message, details: details)))
//      } else {
//        completion(.success(Void()))
//      }
//    }
//  }
//}
