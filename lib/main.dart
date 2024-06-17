import 'package:flutter/material.dart';

import 'lib/src/todo_list_page.dart';

void main() {
  runApp(const TodoVoiceApp());
}

class TodoVoiceApp extends StatelessWidget {
  const TodoVoiceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "Keith's List",
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TodoListPage(),
      );
}
