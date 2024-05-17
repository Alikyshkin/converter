import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';

Widget buildDragAndDropArea(List<Map<String, dynamic>> selectedImages, void Function(void Function()) setState) {
  return DragTarget<html.File>(
    onAccept: (file) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        Uint8List imageData = reader.result as Uint8List;
        String extension = file.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp'].contains(extension)) {
          print('Формат $extension не поддерживается');
          return;
        }
        setState(() {
          selectedImages.add({
            'name': file.name,
            'originalBytes': imageData,
            'compressedBytes': null,
            'originalSize': file.size,
            'compressedSize': null,
            'originalExtension': extension,
            'compressedExtension': null
          });
        });
      });
    },
    builder: (context, candidateData, rejectedData) {
      return Container(
        height: 200,
        width: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Перетащите фото сюда',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
      );
    },
  );
}
