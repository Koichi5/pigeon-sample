// Autogenerated from Pigeon (v22.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

private class WatchCommunicationPigeonCodecReader: FlutterStandardReader {
}

private class WatchCommunicationPigeonCodecWriter: FlutterStandardWriter {
}

private class WatchCommunicationPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return WatchCommunicationPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return WatchCommunicationPigeonCodecWriter(data: data)
  }
}

class WatchCommunicationPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = WatchCommunicationPigeonCodec(readerWriter: WatchCommunicationPigeonCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol WatchCommunicationApi {
  func triggerSave() throws
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class WatchCommunicationApiSetup {
  static var codec: FlutterStandardMessageCodec { WatchCommunicationPigeonCodec.shared }
  /// Sets up an instance of `WatchCommunicationApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: WatchCommunicationApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let triggerSaveChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_sample.WatchCommunicationApi.triggerSave\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      triggerSaveChannel.setMessageHandler { _, reply in
        do {
          try api.triggerSave()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      triggerSaveChannel.setMessageHandler(nil)
    }
  }
}
