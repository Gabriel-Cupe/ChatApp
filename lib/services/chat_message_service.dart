import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/services/database_service.dart';

class ChatMessageService {
  final DatabaseService databaseService;

  ChatMessageService(this.databaseService);

  // El stream global fue eliminado para evitar lags

  Future<void> sendMessage({
    required String sender,
    required String text,
    String? replyTo,
    String? imageUrl,
  }) async {
    await databaseService.sendMessage(
      sender,
      text,
      replyTo: replyTo,
      imageUrl: imageUrl,
    );
  }

  Future<List<Message>> getInitialMessages({int limit = 30}) {
    return databaseService.getLastMessages(limit: limit);
  }

  Future<List<Message>> loadMoreMessages(int beforeTimestamp, {int limit = 30}) {
    return databaseService.loadMoreMessages(beforeTimestamp, limit: limit);
  }

  Future<void> markMessageAsSeen(String messageId) async {
    await databaseService.markMessageAsSeen(messageId);
  }
}
