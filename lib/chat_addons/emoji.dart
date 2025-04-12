import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'emoji_list.dart';

class EmojiPickerWidget extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({Key? key, required this.onEmojiSelected}) 
    : super(key: key);

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  final List<String> _loadedEmojis = [];
  int _emojiIndex = 0;
  final ScrollController _scrollController = ScrollController();
  Timer? _loadTimer;
  Timer? _repeatTimer;
  double _currentOffset = 10.0;
  bool _isKeyDown = false;

  @override
  void initState() {
    super.initState();
    _loadEmojisGradually();
    _enableScrollWithKeyboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loadTimer?.cancel();
    _repeatTimer?.cancel();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  void _loadEmojisGradually() {
    _loadTimer?.cancel(); // Cancelar cualquier timer existente
    
    _loadTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_emojiIndex < emojiList.length) {
        final endIndex = (_emojiIndex + 5).clamp(0, emojiList.length);
        final newEmojis = emojiList.sublist(_emojiIndex, endIndex);
        
        setState(() {
          _loadedEmojis.addAll(newEmojis);
          _emojiIndex = endIndex;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _scroll(int direction) {
    if (!mounted || !_scrollController.hasClients) return;
    
    final target = _scrollController.offset + direction * _currentOffset;
    _scrollController.animateTo(
      target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!mounted) return;

    if (event is RawKeyDownEvent && !_isKeyDown) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _isKeyDown = true;
        int direction = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
        _currentOffset = 10.0;

        _scroll(direction);

        _repeatTimer?.cancel();
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
          if (!mounted) return;
          _scroll(direction);
          _currentOffset += 15;
          if (_currentOffset > 300) _currentOffset = 300;
        });
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _repeatTimer?.cancel();
        _repeatTimer = null;
        _currentOffset = 10.0;
        _isKeyDown = false;
      }
    }
  }

  void _enableScrollWithKeyboard() {
    if (mounted) {
      RawKeyboard.instance.addListener(_handleKeyEvent);
    }
  }

@override
Widget build(BuildContext context) {
  return Container(
    height: 250,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1.0,
      ),
      padding: const EdgeInsets.all(12),
      itemCount: _loadedEmojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (mounted && widget.onEmojiSelected != null) {
              widget.onEmojiSelected(_loadedEmojis[index]);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                _loadedEmojis[index], 
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}