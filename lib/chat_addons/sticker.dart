import 'package:flutter/material.dart';

class StickerPickerWidget extends StatelessWidget {
  final Function(String) onStickerSelected;

  StickerPickerWidget({
    Key? key,
    required this.onStickerSelected,
  }) : super(key: key);

  final List<String> stickers = [
'https://i.ibb.co/1fw5QrnX/sticker1.png',
'https://i.ibb.co/fdttcHPY/sticker2.png',
'https://i.ibb.co/ns4Lnr9d/sticker3.png',
'https://i.ibb.co/pjZ0ZrnL/sticker4.png',
'https://i.ibb.co/8LwcThXf/sticker5.png',
'https://i.ibb.co/FkmCx0S2/sticker6.png',
'https://i.ibb.co/G4MdJH1c/sticker7.png',
'https://i.ibb.co/3YsRb2Dx/sticker8.png',
'https://i.ibb.co/yFPV0Q5p/sticker9.png',
   
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onStickerSelected(stickers[index]),
          child: Image.network(
            stickers[index],
            loadingBuilder: (context, child, progress) {
              return progress == null 
                  ? child 
                  : const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          ),
        );
      },
    );
  }
}