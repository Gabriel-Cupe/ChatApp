// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:chat_app/chat_addons/chat_bubble.dart';
import 'package:chat_app/chat_addons/confetti_effect.dart';
import 'package:chat_app/chat_addons/image_service.dart';
import 'package:chat_app/chat_addons/love_message_dialog.dart';
import 'package:chat_app/chat_addons/message_input.dart';
import 'package:chat_app/chat_addons/reply_panel.dart';
import 'package:chat_app/chat_addons/scroll.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/notis/timer_menu.dart';
import 'package:chat_app/services/chat_message_service.dart';
import 'package:chat_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ChatScreen extends StatefulWidget {
  final User user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatMessageService _messageService = ChatMessageService(DatabaseService());
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  late StreamSubscription<List<Message>> _messagesSubscription;

  Message? _replyingTo;
  bool _showReplyPanel = false;
  dynamic _selectedImage;
  String? _imagePreviewUrl;
  bool _isWeb = false;

@override
void initState() {
  super.initState();
  _isWeb = kIsWeb;
  _loadInitialMessages();
  enableScrollWithKeyboard(_scrollController);

  final db = _messageService.databaseService;

  // Escuchar nuevos mensajes
  db.newMessageStream.listen((event) {
    if (event.snapshot.value != null) {
      final newMessage = Message.fromMap(
        event.snapshot.key!,
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
      final exists = _messages.any((m) => m.id == newMessage.id);
      if (!exists) {
        setState(() {
          _messages.add(newMessage);
        });
        scrollToBottom();
      }
    }
  });

  // Escuchar ediciones
  db.messageEditStream.listen((event) {
    if (event.snapshot.value != null) {
      final updated = Message.fromMap(
        event.snapshot.key!,
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
      final index = _messages.indexWhere((m) => m.id == updated.id);
      if (index != -1) {
        setState(() {
          _messages[index] = updated;
        });
      }
    }
  });

  // Escuchar eliminaciones
  db.messageDeleteStream.listen((event) {
    setState(() {
      _messages.removeWhere((m) => m.id == event.snapshot.key);
    });
  });

  _scrollController.addListener(_scrollListener);
}


  void _scrollListener() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 50 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    final messages = await _messageService.getInitialMessages();
    if (mounted) {
      setState(() {
        _messages = messages;
      });
    }
    scrollToBottom();
  }

  Future<void> _loadMoreMessages() async {
    if (_messages.isEmpty) return;
    _isLoadingMore = true;

    final before = _scrollController.position.pixels;
    final oldest = _messages.first;
    final moreMessages = await _messageService.loadMoreMessages(
        oldest.timestamp.millisecondsSinceEpoch);

    if (mounted) {
      setState(() {
        if (moreMessages.isEmpty) {
          _hasMore = false;
        } else {
          _messages = [...moreMessages, ..._messages];
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.pixels + before);
    });

    _isLoadingMore = false;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isNotEmpty || _selectedImage != null) {
      String? imageUrl;

      if (_selectedImage is String && (_selectedImage as String).startsWith('http')) {
        imageUrl = _selectedImage as String;
      } else if (_selectedImage != null) {
        if (_isWeb && _selectedImage is Uint8List) {
          imageUrl = await ImageService.uploadImageFromBytes(_selectedImage);
        } else if (!_isWeb && _selectedImage is String) {
          imageUrl = await ImageService.uploadImage(_selectedImage);
        }
      }

      await _messageService.sendMessage(
        sender: widget.user.displayName,
        text: text.isNotEmpty ? text : (imageUrl != null ? '[contenido multimedia]' : ''),
        replyTo: _replyingTo?.id,
        imageUrl: imageUrl,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          if (_isWeb && _imagePreviewUrl != null) {
            html.Url.revokeObjectUrl(_imagePreviewUrl!);
            _imagePreviewUrl = null;
          }
        });
      }
      _cancelReply();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _startReply(Message message) {
    setState(() {
      _replyingTo = message;
      _showReplyPanel = true;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _showReplyPanel = false;
    });
  }

  void _handleImageSelected(dynamic imageData) {
    if (_isWeb && imageData is Uint8List) {
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      setState(() {
        _selectedImage = imageData;
        _imagePreviewUrl = url;
      });
    } else if (!_isWeb && imageData is String) {
      setState(() {
        _selectedImage = imageData;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isWeb
                ? Image.network(
                    _imagePreviewUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_selectedImage),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  setState(() {
                    if (_isWeb && _imagePreviewUrl != null) {
                      html.Url.revokeObjectUrl(_imagePreviewUrl!);
                    }
                    _selectedImage = null;
                    _imagePreviewUrl = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.sender == widget.user.displayName;

        return ChatBubble(
          message: message,
          isMe: isMe,
          onStartReply: _startReply,
          dbService: DatabaseService(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chat App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Row(
            children: [
              Container(
                width: 10,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.lightGreenAccent.withOpacity(0.5), blurRadius: 4, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.user.displayName} • En línea',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color(0xFFeb3af3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 10,
actions: [
  IconButton(
    icon: const Icon(Icons.arrow_downward, color: Colors.white),
    tooltip: 'Ir abajo',
    onPressed: scrollToBottom,
  ),
  const TimerMenu(),
  IconButton(
    icon: const Icon(Icons.more_vert, color: Colors.white),
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) => LoveMessageDialog(onConfetti: () => _showConfetti()),
      );
    },
  ),
],

    );
  }

  void _showConfetti() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConfettiEffect(message: '❤ TE AMO JANDYSITA❤'),
    ).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFfff4fc), Color(0xFFfff4fc)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildMessageList(),
            ),
          ),
          _buildImagePreview(),
          if (_replyingTo != null && _showReplyPanel)
            ReplyPanel(
              replyingTo: _replyingTo!,
              onCancel: _cancelReply,
            ),
          MessageInput(
            focusNode: _focusNode,
            controller: _messageController,
            replyingTo: _replyingTo,
            onCancelReply: _cancelReply,
            onSend: _sendMessage,
            onImageSelected: _handleImageSelected,
            onStickerSelected: (stickerUrl) {
              _messageService.sendMessage(
                sender: widget.user.displayName,
                text: '[sticker]',
                imageUrl: stickerUrl,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    if (_isWeb && _imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }
    super.dispose();
  }
}