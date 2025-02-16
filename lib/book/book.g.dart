// Autogenerated from Pigeon (v22.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class Book {
  Book({
    this.id,
    required this.title,
    required this.publisher,
    required this.imageUrl,
    required this.lastModified,
  });

  String? id;

  String title;

  String publisher;

  String imageUrl;

  int lastModified;

  Object encode() {
    return <Object?>[
      id,
      title,
      publisher,
      imageUrl,
      lastModified,
    ];
  }

  static Book decode(Object result) {
    result as List<Object?>;
    return Book(
      id: result[0] as String?,
      title: result[1]! as String,
      publisher: result[2]! as String,
      imageUrl: result[3]! as String,
      lastModified: result[4]! as int,
    );
  }
}

class Record {
  Record({
    this.id,
    required this.book,
    required this.seconds,
    required this.createdAt,
    required this.lastModified,
  });

  String? id;

  Book book;

  int seconds;

  int createdAt;

  int lastModified;

  Object encode() {
    return <Object?>[
      id,
      book,
      seconds,
      createdAt,
      lastModified,
    ];
  }

  static Record decode(Object result) {
    result as List<Object?>;
    return Record(
      id: result[0] as String?,
      book: result[1]! as Book,
      seconds: result[2]! as int,
      createdAt: result[3]! as int,
      lastModified: result[4]! as int,
    );
  }
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    }    else if (value is Book) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    }    else if (value is Record) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129:
        return Book.decode(readValue(buffer)!);
      case 130:
        return Record.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class BookFlutterApi {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  Future<List<Book>> fetchBooks();

  void addBook(Book book);

  void deleteBook(Book book);

  Future<List<Record>> fetchRecords();

  void addRecord(Record record);

  void deleteRecord(Record record);

  void startTimer(int? count);

  void stopTimer();

  static void setUp(BookFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.fetchBooks$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          try {
            final List<Book> output = await api.fetchBooks();
            return wrapResponse(result: output);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addBook$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addBook was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Book? arg_book = (args[0] as Book?);
          assert(arg_book != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addBook was null, expected non-null Book.');
          try {
            api.addBook(arg_book!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteBook$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteBook was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Book? arg_book = (args[0] as Book?);
          assert(arg_book != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteBook was null, expected non-null Book.');
          try {
            api.deleteBook(arg_book!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.fetchRecords$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          try {
            final List<Record> output = await api.fetchRecords();
            return wrapResponse(result: output);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addRecord$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addRecord was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Record? arg_record = (args[0] as Record?);
          assert(arg_record != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.addRecord was null, expected non-null Record.');
          try {
            api.addRecord(arg_record!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteRecord$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteRecord was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Record? arg_record = (args[0] as Record?);
          assert(arg_record != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.deleteRecord was null, expected non-null Record.');
          try {
            api.deleteRecord(arg_record!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.startTimer$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BookFlutterApi.startTimer was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_count = (args[0] as int?);
          try {
            api.startTimer(arg_count);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BookFlutterApi.stopTimer$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          try {
            api.stopTimer();
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
