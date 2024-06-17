import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';

import '../animated_todo.dart';
import 'speech.dart';
import 'toast.dart';
import 'todo_item.dart';
import 'widgets/pulsing_mic_icon.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  Speech speech = Speech();

  final _listKey = GlobalKey<AnimatedTodoListState>();

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    speech.init(onConverted: (text) async {
      if (text.isNotEmpty) {
        await _addTodoItem(text);
        print('Adding Item');
      } else {
        showBottomToast(context, "Sorry, I didn't hear anything.");
      }
      setState(() {});
    }, onError: (error) {
      showBottomToast(context, error.errorMsg);
      setState(() {});
    });
  }

  Future<void> _addTodoItem(String text) async {
    final item = TodoItem(text: text);
    await _listKey.currentState?.add(item);
    setState(() {});
  }

  /// Start Listening
  Future<void> _startListening() async {
    await speech.start();
    setState(() {});
  }

  /// Stop Listening
  Future<void> _stopListening() async {
    await speech.stop();
    setState(() {});
  }

  /// Build the main body.
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Keith's List")),
        body: FutureBuilderEx(
            future: speech.isInitialised,
            errorBuilder: (context, error) => Text(error.toString()),
            builder: (context, speech) => Column(
                  children: [
                    Expanded(child: AnimatedTodoList(key: _listKey)),
                    if (!speech!.isListening)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDeleteAllButton(context),
                          _buildAddButton(),
                        ],
                      ),
                    if (speech.isListening)
                      Column(
                        children: [
                          _buildSpeakNow(),
                          _buildStop(),
                        ],
                      ),
                  ],
                )),
      );

  /// Delete All button
  Widget _buildDeleteAllButton(BuildContext context) => Expanded(
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  content: const Text(
                      'Do you want to delete all items from the list?',
                      style: TextStyle(fontSize: 22)),
                  actions: [
                    _buildNoButton(context),
                    _buildYesButton(context),
                  ],
                ),
              );
            },
            child: const Text('Delete All',
                style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
        ),
      );

  /// Add button
  Widget _buildAddButton() => Expanded(
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: _startListening,
            child: const Text('Add',
                style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
        ),
      );

  /// yes button
  ElevatedButton _buildYesButton(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(100, 50),
        ),
        onPressed: () async {
          await _listKey.currentState?.deleteAllItems();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: const Text('Yes', style: TextStyle(color: Colors.white)),
      );

  /// no button
  ElevatedButton _buildNoButton(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(100, 50),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('No', style: TextStyle(color: Colors.white)),
      );

  /// Build the stop button
  Widget _buildStop() => SizedBox(
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
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
      );

  /// Build the speak now icon.
  Widget _buildSpeakNow() => const SizedBox(
        height: 120,
        child: Column(
          children: [
            Text('Speak Now', style: TextStyle(fontSize: 22)),
            SizedBox(
              height: 80,
              width: 80,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: ColoredBox(
                  color: Colors.white,
                  child: PulsingMicIcon(),
                ),
              ),
            ),
          ],
        ),
      );
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Speech>('speech', speech));
  }
}
