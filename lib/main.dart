import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const TodoVoiceApp());
}

class TodoVoiceApp extends StatelessWidget {
  const TodoVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Voice App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<TodoItem> _todoItems = [];
  bool _isListening = false;
  late stt.SpeechToText _speech;
  String _newItemText = '';

  @override
  void initState() {
    super.initState();
    _loadTodoItems();
    _speech = stt.SpeechToText();
  }

  void _loadTodoItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> items = prefs.getStringList('todoItems') ?? [];
    setState(() {
      _todoItems = items.map((item) => TodoItem.fromJson(item)).toList();
    });
  }

  void _saveTodoItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> items = _todoItems.map((item) => item.toJson()).toList();
    prefs.setStringList('todoItems', items);
  }

  void _addTodoItem(String text) {
    setState(() {
      _todoItems.add(TodoItem(text: text));
      _saveTodoItems();
    });
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
      _saveTodoItems();
    });
  }

  void _toggleComplete(int index) {
    setState(() {
      TodoItem item = _todoItems.removeAt(index);
      item.isComplete = !item.isComplete;
      _todoItems.add(item);
      _saveTodoItems();
    });
  }

  void _deleteAllItems() {
    setState(() {
      _todoItems.clear();
      _saveTodoItems();
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() => _newItemText = result.recognizedWords);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      if (_newItemText.isNotEmpty) {
        _addTodoItem(_newItemText);
        _newItemText = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _todoItems.length,
              itemBuilder: (context, index) {
                final item = _todoItems[index];
                final backgroundColor =
                    index.isEven ? Colors.white : Colors.purple.shade50;

                return Container(
                  color: backgroundColor,
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Item'),
                              content:
                                  Text('Do you want to delete "${item.text}"?'),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    _deleteTodoItem(index);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Yes'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('No'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    title: Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 18.0,
                        decoration: item.isComplete
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: null,
                    ),
                    trailing: Checkbox(
                      value: item.isComplete,
                      onChanged: (value) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Mark Item as Complete'),
                              content: Text(
                                  'Do you want to mark "${item.text}" as complete?'),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    _toggleComplete(index);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_isListening)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete All Items'),
                            content: const Text(
                                'Do you want to delete all items in the list?'),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  _deleteAllItems();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Yes'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('No'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Delete All',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: _startListening,
                    child: const Text('Add',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          if (_isListening)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: _stopListening,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stop,
                          color: Colors.white,
                        ),
                        Text('Stop', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {},
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.white),
                        Text('Speak Now',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class TodoItem {
  String text;
  bool isComplete;

  TodoItem({required this.text, this.isComplete = false});

  String toJson() => jsonEncode({'text': text, 'isComplete': isComplete});

  factory TodoItem.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return TodoItem(
      text: map['text'],
      isComplete: map['isComplete'],
    );
  }
}
