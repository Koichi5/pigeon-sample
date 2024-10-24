import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pigeon_sample/todo/todo.g.dart';

class TodoFlutterApiImpl extends TodoFlutterApi {
  @override
  Future<void> addTodo(Todo todo) async {
    await FirebaseFirestore.instance.collection('todos').add({
      'id': todo.id,
      'title': todo.title,
      'description': todo.description,
      'isDone': todo.isDone
    });
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    await FirebaseFirestore.instance.collection('todos').doc(todo.id).delete();
  }

  @override
  Future<List<Todo?>> fetchTodos() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('todos').get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      return Todo(
        id: doc.id,
        title: data['title'] as String,
        description: data['description'] as String,
        isDone: data['isDone'] as bool,
      );
    }).toList();
  }
}
