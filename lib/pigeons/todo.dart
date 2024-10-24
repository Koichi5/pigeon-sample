import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/todo/todo.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Todo/Todo.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Todo/Todo.g.swift',
  swiftOptions: SwiftOptions(),
))

class Todo {
  Todo(this.id, this.title, this.description, this.isDone);

  String id;
  String title;
  String description;
  bool isDone;
}

@FlutterApi()
abstract class TodoFlutterApi {
  void addTodo(Todo todo);
  void deleteTodo(Todo todo);
  @async
  List<Todo?> fetchTodos();
}
