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


private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Generated class from Pigeon that represents data sent in messages.
struct Book {
  var id: String? = nil
  var title: String
  var publisher: String
  var imageUrl: String
  var lastModified: Int64



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> Book? {
    let id: String? = nilOrValue(pigeonVar_list[0])
    let title = pigeonVar_list[1] as! String
    let publisher = pigeonVar_list[2] as! String
    let imageUrl = pigeonVar_list[3] as! String
    let lastModified = pigeonVar_list[4] as! Int64

    return Book(
      id: id,
      title: title,
      publisher: publisher,
      imageUrl: imageUrl,
      lastModified: lastModified
    )
  }
  func toList() -> [Any?] {
    return [
      id,
      title,
      publisher,
      imageUrl,
      lastModified,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct Record {
  var id: String? = nil
  var book: Book
  var seconds: Int64
  var createdAt: Int64
  var lastModified: Int64



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> Record? {
    let id: String? = nilOrValue(pigeonVar_list[0])
    let book = pigeonVar_list[1] as! Book
    let seconds = pigeonVar_list[2] as! Int64
    let createdAt = pigeonVar_list[3] as! Int64
    let lastModified = pigeonVar_list[4] as! Int64

    return Record(
      id: id,
      book: book,
      seconds: seconds,
      createdAt: createdAt,
      lastModified: lastModified
    )
  }
  func toList() -> [Any?] {
    return [
      id,
      book,
      seconds,
      createdAt,
      lastModified,
    ]
  }
}

private class BookPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return Book.fromList(self.readValue() as! [Any?])
    case 130:
      return Record.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class BookPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? Book {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? Record {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class BookPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return BookPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return BookPigeonCodecWriter(data: data)
  }
}

class BookPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = BookPigeonCodec(readerWriter: BookPigeonCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol BookFlutterApiProtocol {
  func fetchBooks(completion: @escaping (Result<[Book], PigeonError>) -> Void)
  func addBook(book bookArg: Book, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func deleteBook(book bookArg: Book, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func fetchRecords(completion: @escaping (Result<[Record], PigeonError>) -> Void)
  func addRecord(record recordArg: Record, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func deleteRecord(record recordArg: Record, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class BookFlutterApi: BookFlutterApiProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: BookPigeonCodec {
    return BookPigeonCodec.shared
  }
  func fetchBooks(completion: @escaping (Result<[Book], PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.fetchBooks\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage(nil) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else if listResponse[0] == nil {
        completion(.failure(PigeonError(code: "null-error", message: "Flutter api returned null value for non-null return value.", details: "")))
      } else {
        let result = listResponse[0] as! [Book]
        completion(.success(result))
      }
    }
  }
  func addBook(book bookArg: Book, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addBook\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([bookArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func deleteBook(book bookArg: Book, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteBook\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([bookArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func fetchRecords(completion: @escaping (Result<[Record], PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.fetchRecords\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage(nil) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else if listResponse[0] == nil {
        completion(.failure(PigeonError(code: "null-error", message: "Flutter api returned null value for non-null return value.", details: "")))
      } else {
        let result = listResponse[0] as! [Record]
        completion(.success(result))
      }
    }
  }
  func addRecord(record recordArg: Record, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addRecord\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([recordArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func deleteRecord(record recordArg: Record, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteRecord\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([recordArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
