import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class MessageMenu extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function(Message) onReply;
  final DatabaseService dbService;

  const MessageMenu({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.dbService,
  }) : super(key: key);

  void _showModalMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
backgroundColor: const Color(0xCCFFF7FE),
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xCCFFF7FE),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
  _buildMenuItem(
    context,
    icon: Icons.reply_outlined,
    text: 'Responder',
    iconColor: Colors.blueAccent,
    textColor: Colors.black87,
    onTap: () {
      Navigator.pop(context);
      onReply(message);
    },
  ),
  if (isMe)
    _buildMenuItem(
      context,
      icon: Icons.edit_outlined,
      text: 'Editar mensaje',
      iconColor: Colors.blueAccent,
      textColor: Colors.black87,
      onTap: () => _editMessage(context),
    ),
  _buildMenuItem(
    context,
    icon: Icons.copy_outlined,
    text: 'Copiar texto',
    iconColor: Colors.blueAccent,
    textColor: Colors.black87,
    onTap: () => _copyToClipboard(context),
  ),
  if (isMe)
    _buildMenuItem(
      context,
      icon: Icons.delete_rounded,
      text: 'Eliminar mensaje',
      iconColor: Colors.red,
      textColor: Colors.black87,
      onTap: () => _deleteMessage(context),
    ),
  const SizedBox(height: 8),
  _buildMenuItem(
    context,
    icon: Icons.close,
    text: 'Cancelar',
    iconColor: Colors.grey,
    textColor: Colors.black45,
    onTap: () => Navigator.pop(context),
  ),
]

          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
  BuildContext context, {
  required IconData icon,
  required String text,
  required VoidCallback onTap,
  Color iconColor = Colors.black,
  Color textColor = Colors.black,
}) {
  return ListTile(
    leading: Icon(icon, color: iconColor),
    title: Text(text, style: TextStyle(color: textColor)),
    onTap: onTap,
  );
}

Future<void> _editMessage(BuildContext context) async {
  Navigator.pop(context);
  final textController = TextEditingController(text: message.text);
  
  final edited = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar mensaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              maxLines: 4,
              style: TextStyle(color: Colors.grey[800]),
              decoration: InputDecoration(
                hintText: 'Escribe aquí...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue.shade200,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (edited == true && textController.text.trim().isNotEmpty) {
    await dbService.editMessage(message.id, textController.text);
  }
}

Future<void> _deleteMessage(BuildContext context) async {
  Navigator.pop(context);
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.orange.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Eliminar mensaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Estás seguro de eliminar este mensaje?\nEsta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed == true) {
    await dbService.deleteMessage(message.id);
  }
}

void _copyToClipboard(BuildContext context) {
  Clipboard.setData(ClipboardData(text: message.text));
  Navigator.pop(context);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 10), // Ajusta según tu UI
      content: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade400, // Verde de éxito
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Texto copiado al portapapeles',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 1),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showModalMenu(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.3) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: isMe ? Colors.white70 : Colors.grey[600],
        ),
      ),
    );
  }

}