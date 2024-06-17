import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/todo_item.dart';

class AnimatedTodoList extends StatefulWidget {
  const AnimatedTodoList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  AnimatedTodoListState createState() => AnimatedTodoListState();
}

class AnimatedTodoListState extends State<AnimatedTodoList> {
  final List<TodoItem> list = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late Future<void> loadComplete;
  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    loadComplete = _loadTodoItems();
  }

  @override
  Widget build(BuildContext context) => FutureBuilderEx(
      // ignore: discarded_futures
      future: loadComplete,
      builder: (context, _) => AnimatedList(
          key: _listKey,
          initialItemCount: list.length,
          itemBuilder: (context, index, animation) =>
              _buildItem(list[index], index, animation)));

  Future<void> _loadTodoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('todoItems') ?? [];
    print('Loading ${items.length} items');
    list.addAll(items.map(TodoItem.fromJson).toList());
    for (var i = 0; i < list.length; i++) {
      _listKey.currentState?.insertItem(i);
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final items = list.map((item) => item.toJson()).toList();
    await prefs.setStringList('todoItems', items);
  }

  Future<void> add(TodoItem item) async {
    var completedItems = 0;

    /// insert the item after the last completed item.
    if (list.isNotEmpty) {
      completedItems = list.indexWhere((item) => item.isComplete == true);
    }

    // If no completed items then insert at the beginning..
    if (completedItems == -1) {
      completedItems = 0;
    }

    _listKey.currentState?.insertItem(0);
    list.insert(0, item);
    await save();
  }

  Future<void> delete(int index) async {
    final removedItem = list.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, index, animation),
    );
    await save();
  }

  Future<void> deleteAllItems() async {
    final itemCount = list.length;
    for (var i = itemCount - 1; i >= 0; i--) {
      final item = list[i];
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildRemovedItem(item, animation),
      );
    }
    setState(list.clear);
    await save();
  }

  Widget _buildRemovedItem(TodoItem item, Animation<double> animation) =>
      SizeTransition(
        sizeFactor: animation,
        child: ColoredBox(
          color: item.isComplete ? Colors.green.shade100 : Colors.red.shade100,
          child: ListTile(
            title: Text(
              item.text,
              style: TextStyle(
                decoration: item.isComplete
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
      );

  Future<void> _toggleComplete(int index) async {
    final item = list[index];
    setState(() {
      list.removeAt(index);
      item.isComplete = !item.isComplete;
      list.add(item);
    });
    await save();
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(item, index, animation),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _listKey.currentState?.insertItem(list.length - 1);
    });
  }

  Widget _buildItem(TodoItem item, int index, Animation<double> animation) {
    final backgroundColor = index.isEven ? Colors.white : Colors.purple.shade50;

    return SizeTransition(
      sizeFactor: animation,
      child: ColoredBox(
        color: backgroundColor,
        child: ListTile(
          leading: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text('Do you want to delete "${item.text}"?',
                      style: const TextStyle(fontSize: 20)),
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
                        delete(index);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
            },
          ),
          title: Text(
            item.text,
            style: TextStyle(
              fontSize: 18,
              decoration: item.isComplete
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          trailing: Checkbox(
            value: item.isComplete,
            onChanged: (value) async {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(
                      'Do you want to mark "${item.text}" as complete?',
                      style: const TextStyle(fontSize: 22)),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<TodoItem>('list', list))
      ..add(DiagnosticsProperty<Future<void>>('loadComplete', loadComplete));
  }
}
