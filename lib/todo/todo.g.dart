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

class Todo {
  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
  });

  String id;

  String title;

  String description;

  bool isDone;

  Object encode() {
    return <Object?>[
      id,
      title,
      description,
      isDone,
    ];
  }

  static Todo decode(Object result) {
    result as List<Object?>;
    return Todo(
      id: result[0]! as String,
      title: result[1]! as String,
      description: result[2]! as String,
      isDone: result[3]! as bool,
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
    }    else if (value is Todo) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129: 
        return Todo.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class TodoFlutterApi {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  void addTodo(Todo todo);

  void deleteTodo(Todo todo);

  Future<List<Todo?>> fetchTodos();

  static void setUp(TodoFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.addTodo$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.addTodo was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Todo? arg_todo = (args[0] as Todo?);
          assert(arg_todo != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.addTodo was null, expected non-null Todo.');
          try {
            api.addTodo(arg_todo!);
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
          'dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.deleteTodo$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.deleteTodo was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final Todo? arg_todo = (args[0] as Todo?);
          assert(arg_todo != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.deleteTodo was null, expected non-null Todo.');
          try {
            api.deleteTodo(arg_todo!);
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
          'dev.flutter.pigeon.pigeon_sample.TodoFlutterApi.fetchTodos$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          try {
            final List<Todo?> output = await api.fetchTodos();
            return wrapResponse(result: output);
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