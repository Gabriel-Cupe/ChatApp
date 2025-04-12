import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class DatabaseService {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('messages');

  Stream<List<Message>> getMessages() {
    return _messagesRef.onValue.map((event) {
      final List<Message> messages = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          messages.add(Message.fromMap(
              key.toString(), Map<String, dynamic>.from(value as Map<dynamic, dynamic>)));
        });
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

Future<void> sendMessage(
  String sender, 
  String text, {
  String? replyTo,
  String? imageUrl,
}) async {
  final newMessageRef = _messagesRef.push();
  await newMessageRef.set({
    'sender': sender,
    'text': text,
    'timestamp': ServerValue.timestamp,
    'edited': false,
    'replyTo': replyTo,
    'imageUrl': imageUrl,
    'isSeen': false, // Por defecto no leído
  });
}

  Future<void> editMessage(String messageId, String newText) async {
    await _messagesRef.child(messageId).update({
      'text': newText,
      'edited': true,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _messagesRef.child(messageId).remove();
  }

  Future<Message?> getMessage(String messageId) async {
    final snapshot = await _messagesRef.child(messageId).get();
    if (snapshot.exists) {
      return Message.fromMap(
          messageId, Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>));
    }
    return null;
  }
  Future<void> markMessageAsSeen(String messageId) async {
  await _messagesRef.child(messageId).update({
    'isSeen': true,
  });
}
}

