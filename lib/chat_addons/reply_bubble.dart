import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/message_model.dart';

class ReplyBubble extends StatelessWidget {
  final String messageId;
  final bool isMe;
  final Function(Message) onTap;

  const ReplyBubble({
    Key? key,
    required this.messageId,
    required this.isMe,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    
    return FutureBuilder<Message?>(
      future: databaseService.getMessage(messageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        
        final repliedMessage = snapshot.data!;
        return GestureDetector(
          onTap: () => onTap(repliedMessage),
          child: Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 4),
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isMe ? Colors.blue[100]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondiendo a ${repliedMessage.sender}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.blue[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repliedMessage.text,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.blue[800] : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}