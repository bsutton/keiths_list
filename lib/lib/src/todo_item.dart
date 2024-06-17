import 'dart:convert';

class TodoItem {
  TodoItem({required this.text, this.isComplete = false});

  factory TodoItem.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return TodoItem(
      text: map['text'] as String,
      isComplete: map['isComplete'] as bool,
    );
  }
  String text;
  bool isComplete;

  String toJson() => jsonEncode({'text': text, 'isComplete': isComplete});
}
