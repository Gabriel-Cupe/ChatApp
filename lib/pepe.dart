import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> initializeEmojiAndStickerDatabase() async {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // 1. Estructura inicial para emojis
  final Map<String, dynamic> emojisData = {
    "emojis": {
      "romantic": {
        "name": "Románticos",
        "items": [
          '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💕',
          '💞', '💓', '💗', '💖', '💘', '💝', '💟', '❣️', '💌', '😍'
        ]
      },
      "cute": {
        "name": "Tiernos",
        "items": [
          '🐶', '🐱', '🐻', '🐻‍❄️', '🐨', '🐼', '🦊', '🐰', '🐹', '🐭',
          '🦄', '🐧', '🐥', '🦋', '🌈', '🌙', '☀️', '⭐', '☁️', '🌊'
        ]
      },
      "hands": {
        "name": "Manos",
        "items": [
          '🤲', '🙏', '✌️', '🤟', '🤘', '👌', '🤙', '👍', '👋', '🤚',
          '🖐️', '✋', '🖖', '👆', '👇', '👉', '👈', '🫶', '🤝', '🙌'
        ]
      }
    }
  };

  // 2. Estructura inicial para stickers
  final Map<String, dynamic> stickersData = {
    "stickers": {
      "emotions": {
        "name": "Emociones",
        "items": [
          'https://i.ibb.co/1fw5QrnX/sticker1.png',
          'https://i.ibb.co/fdttcHPY/sticker2.png',
          'https://i.ibb.co/ns4Lnr9d/sticker3.png'
        ]
      },
      "animals": {
        "name": "Animales",
        "items": [
          'https://i.ibb.co/pjZ0ZrnL/sticker4.png',
          'https://i.ibb.co/8LwcThXf/sticker5.png'
        ]
      },
      "food": {
        "name": "Comida",
        "items": [
          'https://i.ibb.co/FkmCx0S2/sticker6.png',
          'https://i.ibb.co/G4MdJH1c/sticker7.png'
        ]
      }
    }
  };

  try {
    // Ejecutar ambas escrituras atómicamente
    await dbRef.update({
      ...emojisData,
      ...stickersData
    });
    
    debugPrint("✅ Bases de datos de emojis y stickers inicializadas correctamente");
  } catch (e) {
    debugPrint("❌ Error al inicializar: $e");
  }
}