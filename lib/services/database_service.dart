import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class DatabaseService {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('messages');


  // Nuevo: Escucha solo el último mensaje agregado
  Stream<DatabaseEvent> get newMessageStream =>
      _messagesRef.orderByChild('timestamp').limitToLast(1).onChildAdded;

  // Nuevo: Escucha mensajes editados
  Stream<DatabaseEvent> get messageEditStream => _messagesRef.onChildChanged;

  // Nuevo: Escucha mensajes eliminados
  Stream<DatabaseEvent> get messageDeleteStream => _messagesRef.onChildRemoved;

  // Obtener los últimos N mensajes
  Future<List<Message>> getLastMessages({int limit = 30}) async {
    final snapshot = await _messagesRef
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    return _snapshotToMessages(snapshot);
  }

  // Cargar más mensajes anteriores a cierto timestamp
  Future<List<Message>> loadMoreMessages(int startBefore, {int limit = 30}) async {
    final snapshot = await _messagesRef
        .orderByChild('timestamp')
        .endAt(startBefore - 1)
        .limitToLast(limit)
        .get();

    return _snapshotToMessages(snapshot);
  }

  List<Message> _snapshotToMessages(DataSnapshot snapshot) {
    final List<Message> messages = [];
    if (snapshot.value != null) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        messages.add(Message.fromMap(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        ));
      });
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return messages;
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
      'isSeen': false,
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
        messageId,
        Map<String, dynamic>.from(snapshot.value as Map),
      );
    }
    return null;
  }
Future<void> markMessageAsSeen(String messageId, String recipientUsername) async {
  // Verificar si el destinatario está en línea
  final userRef = FirebaseDatabase.instance.ref().child('users').child(recipientUsername);
  final snapshot = await userRef.child('online').get();

  if (snapshot.exists && snapshot.value == true) {
    // Solo marcar como visto si el destinatario está en línea
    await _messagesRef.child(messageId).update({
      'isSeen': true,
    });
  } else {
    print('El destinatario no está en línea. No se puede marcar como visto.');
  }
}
}
