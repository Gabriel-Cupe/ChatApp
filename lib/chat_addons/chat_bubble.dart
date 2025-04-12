import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import 'reply_bubble.dart';
import 'message_menu.dart';
import 'image_viewer.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function(Message) onStartReply;
  final DatabaseService dbService;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onStartReply,
    required this.dbService,
  }) : super(key: key);

  void _showFullImage(BuildContext context, String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.1,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        'Error al cargar imagen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.replyTo != null)
            ReplyBubble(
              messageId: message.replyTo!,
              isMe: isMe,
              onTap: onStartReply,
            ),
          Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.3,
              minHeight: 40,
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [Colors.blueAccent.shade700, Colors.lightBlue.shade400]
                    : [Colors.white, const Color.fromARGB(255, 252, 254, 255)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message.sender,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    if (!isMe) const SizedBox(height: 4),
                    message.imageUrl != null
                        ? _buildImageOrSticker(context)
                        : Text(
                            message.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.edited)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              'Editado',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        Text(
                          '${message.timestamp.hour > 12 ? message.timestamp.hour - 12 : message.timestamp.hour}:'
                          '${message.timestamp.minute.toString().padLeft(2, '0')} '
                          '${message.timestamp.hour >= 12 ? "PM" : "AM"}'
                          ' ' 
                          '${message.timestamp.day}/${message.timestamp.month}/${message.timestamp.year.toString().substring(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              message.isSeen ? Icons.done_all : Icons.done,
                              size: 18,
                              color: message.isSeen 
                                  ? Colors.lightBlueAccent 
                                  : Colors.blueGrey[400]!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: MessageMenu(
                    message: message,
                    isMe: isMe,
                    onReply: onStartReply,
                    dbService: dbService,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildImageOrSticker(BuildContext context) {
  // Detectar si es sticker (verifica si la URL contiene "sticker" o es de imgBB)
  final isSticker = message.imageUrl!.contains('sticker') || 
                   message.imageUrl!.contains('ibb.co');

  if (isSticker) {
    return GestureDetector(
      onTap: () => _showFullImage(context, message.imageUrl!),
      child: Image.network(
        message.imageUrl!,
        width: 120,  // Tamaño fijo para stickers
        height: 120,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          color: Colors.grey[200],
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      ),
    );
  } else {
    // Es una imagen normal
    return ImageViewer(imageUrl: message.imageUrl!);
  }
}
}