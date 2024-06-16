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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<TodoItem> _todoItems = [];
  bool _isListening = false;
  late stt.SpeechToText _speech;
  String _newItemText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadTodoItems();
  }

  void _loadTodoItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> items = prefs.getStringList('todoItems') ?? [];
    setState(() {
      _todoItems = items.map((item) => TodoItem.fromJson(item)).toList();
      for (var i = 0; i < _todoItems.length; i++) {
        _listKey.currentState?.insertItem(i);
      }
    });
  }

  void _saveTodoItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> items = _todoItems.map((item) => item.toJson()).toList();
    prefs.setStringList('todoItems', items);
  }

  void _addTodoItem(String text) {
    final item = TodoItem(text: text);
    setState(() {
      _todoItems.add(item);
      _listKey.currentState?.insertItem(_todoItems.length - 1);
      _saveTodoItems();
    });
  }

  void _deleteTodoItem(int index) {
    final removedItem = _todoItems.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, index, animation),
    );
    _saveTodoItems();
  }

  void _toggleComplete(int index) {
    final item = _todoItems[index];
    setState(() {
      _todoItems.removeAt(index);
      item.isComplete = !item.isComplete;
      _todoItems.add(item);
      _saveTodoItems();
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(item, index, animation),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _listKey.currentState?.insertItem(_todoItems.length - 1);
    });
  }

  void _deleteAllItems() {
    setState(() {
      final itemCount = _todoItems.length;
      for (int i = itemCount - 1; i >= 0; i--) {
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(_todoItems[i], i, animation),
        );
      }
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

  Widget _buildItem(TodoItem item, int index, Animation<double> animation) {
    final backgroundColor = index.isEven ? Colors.white : Colors.purple.shade50;

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
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
                    content: Text('Do you want to delete "${item.text}"?'),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('No'),
                      ),
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
                    content:
                        Text('Do you want to mark "${item.text}" as complete?'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _todoItems.length,
              itemBuilder: (context, index, animation) {
                return _buildItem(_todoItems[index], index, animation);
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
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(100, 50),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('No'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  minimumSize: const Size(100, 50),
                                ),
                                onPressed: () {
                                  _deleteAllItems();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Yes'),
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
