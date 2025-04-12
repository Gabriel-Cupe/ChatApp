import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:chat_app/chat_addons/image_service.dart';
import 'package:chat_app/chat_addons/scroll.dart';
import 'package:chat_app/services/database_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../chat_addons/chat_bubble.dart';
import '../chat_addons/reply_panel.dart';
import '../chat_addons/message_input.dart';

class ChatScreen extends StatefulWidget {
  final User user;
  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  late Stream<List<Message>> _messagesStream;
  Message? _replyingTo;
  bool _showReplyPanel = false;
  dynamic _selectedImage; // Puede ser File (mobile) o Uint8List (web)
  String? _imagePreviewUrl;
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
    _messagesStream = _databaseService.getMessages();
  enableScrollWithKeyboard(_scrollController); // ← aquí lo llamas

  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Limpiar URL de objeto en web
    if (_isWeb && _imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }
    super.dispose();
  }


Future<void> _sendMessage() async {
  final text = _messageController.text.trim();
  
  // Verificar si tenemos contenido para enviar
  if (text.isNotEmpty || _selectedImage != null) {
    String? imageUrl;
    
    // Manejo diferente para stickers vs imágenes normales
    if (_selectedImage is String && (_selectedImage as String).startsWith('http')) {
      // Es un sticker (ya es una URL)
      imageUrl = _selectedImage as String;
    } else if (_selectedImage != null) {
      // Es una imagen normal que necesita upload
      if (_isWeb && _selectedImage is Uint8List) {
        imageUrl = await ImageService.uploadImageFromBytes(_selectedImage);
      } else if (!_isWeb && _selectedImage is String) {
        imageUrl = await ImageService.uploadImage(_selectedImage);
      }
    }

    // Enviar el mensaje
    _databaseService.sendMessage(
      widget.user.displayName, 
      text.isNotEmpty ? text : (imageUrl != null ? '[contenido multimedia]' : ''),
      replyTo: _replyingTo?.id,
      imageUrl: imageUrl,
    );
    
    // Limpiar el estado
    _messageController.clear();
    setState(() {
      _selectedImage = null;
      if (_isWeb && _imagePreviewUrl != null) {
        html.Url.revokeObjectUrl(_imagePreviewUrl!);
        _imagePreviewUrl = null;
      }
    });
    _cancelReply();
    _scrollToBottom();
  }
}


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      // Para web: crear URL temporal para la vista previa
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      setState(() {
        _selectedImage = imageData;
        _imagePreviewUrl = url;
      });
    } else if (!_isWeb && imageData is String) {
      // Para móvil/desktop
      setState(() {
        _selectedImage = imageData;
      });
    }
  }


  void _checkMessageVisibility(Message message) {
  final RenderObject? renderObject = _scrollController.position.context.storageContext?.findRenderObject();
  if (renderObject is RenderBox) {
    final messagePosition = renderObject.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (messagePosition.dy < screenHeight && !message.isSeen && message.sender != widget.user.displayName) {
      _databaseService.markMessageAsSeen(message.id);
    }
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
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return 
        ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
itemBuilder: (context, index) {
  final message = messages[index];
  final isMe = message.sender == widget.user.displayName;
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkMessageVisibility(message);
  });

  return ChatBubble(
    message: message,
    isMe: isMe,
    onStartReply: _startReply,
    dbService: _databaseService,
  );
},
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return 
    AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat App',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        Row(
          children: [
            Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.lightGreenAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightGreenAccent.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            Text(
              '${widget.user.displayName} • En línea',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    ),
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent,
const Color(0xFFeb3af3),            
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    ),
    elevation: 10,
    actions: [



IconButton(
  icon: Icon(Icons.more_vert, color: Colors.white),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFCDD2), // Rosa claro
                  Color(0xFFF8BBD0), // Rosa medio
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado con corazón
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 80,
                        ),
                        Icon(
                          Icons.favorite_border,
                          color: Colors.pink[300],
                          size: 80,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Mensaje principal
                    Text(
                      'Para mi amor',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF880E4F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Mensaje aleatorio
                    Text(
                      _getRandomLoveMessage(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFC2185B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    
                    // Efecto de confeti al presionar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showConfetti(context); // Efecto de confeti
                      },
                      child: Text(
                        'Cerrar con amor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  },
)



    ],
  );
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
                  colors: [
   Color(0xFFfff4fc), // Lila suave
   Color(0xFFfff4fc), // Lila suave

      //Colores del fondo
                    ],
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
  controller: _messageController,
  replyingTo: _replyingTo,
  onCancelReply: _cancelReply,
  onSend: _sendMessage,
  onImageSelected: _handleImageSelected,
  onStickerSelected: (stickerUrl) {
    _databaseService.sendMessage(
      widget.user.displayName,
      '[sticker]',
      imageUrl: stickerUrl,
    );
  },
)
        ],
      ),
    );
  }

String _getRandomLoveMessage() {
  final messages = [
    'Eres el sol que ilumina mis días más oscuros',
    'Mi corazón late más fuerte cuando estás cerca',
    'No hay nada en este mundo que me haga más feliz que tu sonrisa',
    'Eres mi pensamiento favorito en el día',
    'El amor que siento por ti crece más cada mañana',
    'Eres la razón por la que creo en el destino',
    'Contigo hasta el fin del universo',
  ];
  return messages[Random().nextInt(messages.length)];
}

void _showConfetti(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: ConfettiWidget(
            confettiController: ConfettiController(duration: const Duration(seconds: 1)),
            blastDirection: -1.0,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.pink,
              Colors.red,
              Colors.white,
              Colors.pinkAccent,
            ],
            child: Center(
              child: Text(
                '❤ TE AMO JANDYSITA❤',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.pink,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  ).then((_) => Navigator.pop(context));
}

}