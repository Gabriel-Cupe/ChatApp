// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_final_fields, use_build_context_synchronously, deprecated_member_use

import 'package:chat_app/chat_addons/enter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import 'emoji.dart';
import 'sticker.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Message? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final Function(dynamic) onImageSelected;
  final Function(String) onStickerSelected; // Nueva función para stickers
final FocusNode? focusNode;


  const MessageInput({
    Key? key,
    required this.controller,
    this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
    required this.onImageSelected,
    required this.onStickerSelected,
       this.focusNode,
// Nuevo parámetro requerido
  }) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isWeb = kIsWeb;
  bool _showEmojiMenu = false;

  Future<void> _pickImage() async {
    try {
      if (_isWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            widget.onImageSelected(bytes);
          }
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          widget.onImageSelected(image.path);
        }
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

void _insertEmoji(String emoji) {
  final text = widget.controller.text;
  final selection = widget.controller.selection;
  
  // Verificar que la posición de selección es válida
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(0, text.length);
  
  final newText = text.replaceRange(start, end, emoji);
  
  widget.controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(
      offset: (start + emoji.length).clamp(0, newText.length)
    ),
  );
}

  void _handleStickerSelected(String stickerUrl) {
    widget.onStickerSelected(stickerUrl); // Envía el sticker
    setState(() {
      _showEmojiMenu = false; // Cierra el menú después de seleccionar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showEmojiMenu)
          Container(
            height: 250, // Aumenté un poco la altura para mejor visualización
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Colors.blueAccent,
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.emoji_emotions)),
                      Tab(icon: Icon(Icons.stacked_bar_chart)),
                    ],
                  ),
// En el método build, dentro del TabBarView:
Expanded(
  child: TabBarView(
    children: [
      EmojiPickerWidget(
        onEmojiSelected: _insertEmoji,
      ),
      StickerPickerWidget(
        onStickerSelected: _handleStickerSelected,
      ),
    ],
  ),
),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_rounded),
                tooltip: 'Enviar imagen',
                color: Colors.blueAccent,
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emojis y Stickers',
                color: _showEmojiMenu ? Colors.orangeAccent :Colors.blueAccent ,
                onPressed: () {
                  setState(() {
                    _showEmojiMenu = !_showEmojiMenu;
                  });
                },
              ),
              Expanded(
                child: EnterAwareTextField(
                  focusNode: widget.focusNode, // Aplicamos el FocusNode correctamente
                  controller: widget.controller,
                  hintText: widget.replyingTo != null
                      ? 'Escribe tu respuesta...'
                      : 'Escribe un mensaje...',
                  suffixIcon: widget.replyingTo != null
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: widget.onCancelReply,
                        )
                      : null,
                  onSend: widget.onSend,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: widget.onSend,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}