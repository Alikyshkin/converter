import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive_io.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'image_widgets.dart';

class CompressionScreen extends StatefulWidget {
  @override
  _CompressionScreenState createState() => _CompressionScreenState();
}

class _CompressionScreenState extends State<CompressionScreen> {
  List<Map<String, dynamic>> _selectedImages = [];
  int _compressionQuality = 50;
  bool _isCompressing = false;
  bool _isCompressed = false;

  void _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();
    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            Uint8List imageData = reader.result as Uint8List;
            String extension = file.name.split('.').last.toLowerCase();
            if (!['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
              print('Формат $extension не поддерживается');
              return;
            }
            setState(() {
              _selectedImages.add({
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
        }
      }
    });
  }

  void _compressImage() async {
    setState(() {
      _isCompressing = true;
    });

    await Future.delayed(Duration(seconds: 2)); // Имитируем время на сжатие изображения

    for (var image in _selectedImages) {
      final img.Image? decodedImage = img.decodeImage(image['originalBytes']);
      if (decodedImage != null) {
        final compressedBytes = Uint8List.fromList(img.encodeJpg(decodedImage, quality: 100 - _compressionQuality));
        setState(() {
          image['compressedBytes'] = compressedBytes;
          image['compressedSize'] = compressedBytes.length;
          image['compressedExtension'] = 'jpg';
        });
      }
    }

    setState(() {
      _isCompressing = false;
      _isCompressed = true;
    });
  }

  void _downloadImage(Uint8List imageBytes, String name) {
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _downloadAllImages() async {
    if (_selectedImages.isNotEmpty) {
      final archive = Archive();
      for (var image in _selectedImages) {
        if (image['compressedBytes'] != null) {
          archive.addFile(ArchiveFile(image['name'], image['compressedBytes'].length, image['compressedBytes']));
        }
      }
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      final blob = html.Blob([zipData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "compressed_images.zip")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  void _clearImages() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение'),
          content: Text('Уверены что хотите очистить фото?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages = [];
                  _compressionQuality = 50;
                  _isCompressed = false;
                });
                Navigator.of(context).pop();
              },
              child: Text('Да'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Нет'),
            ),
          ],
        );
      },
    );
  }

  void _showImageComparison(BuildContext context, Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text('Сравнение изображений'),
          ),
          body: Center(
            child: Container(
              width: 800,
              height: 400,
              child: Stack(
                children: [
                  Image.memory(image['originalBytes']),
                  Positioned.fill(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerRight,
                        widthFactor: 0.5,
                        child: Image.memory(image['compressedBytes']),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 3,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          // Обновите положение полоски
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isCompressed
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: _clearImages,
              )
            : null,
        title: Text('Сжатие изображений'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: _isCompressing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Сжатие изображений...'),
                    SizedBox(height: 20),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: _clearImages,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (_selectedImages.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildDragAndDropArea(_selectedImages, setState),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _pickImage,
                              child: Text('Выберите фото'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ListView.builder(
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final image = _selectedImages[index];
                                return Card(
                                  child: ListTile(
                                    leading: GestureDetector(
                                      onTap: _isCompressed
                                          ? () => _showImageComparison(context, image)
                                          : null,
                                      child: image['compressedBytes'] != null
                                          ? Image.memory(image['compressedBytes'])
                                          : Image.memory(image['originalBytes']),
                                    ),
                                    title: Text(image['name']),
                                    subtitle: Text(
                                      'Изначальный размер: ${image['originalSize']} байт\n'
                                      'Сжатый размер: ${image['compressedSize'] ?? 'Не сжато'} байт\n'
                                      'Изначальный формат: ${image['originalExtension']}\n'
                                      'Сжатый формат: ${image['compressedExtension'] ?? 'Не сжато'}',
                                    ),
                                    trailing: image['compressedBytes'] != null
                                        ? IconButton(
                                            icon: Icon(Icons.download),
                                            onPressed: () => _downloadImage(image['compressedBytes'], 'compressed_${image['name']}'),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text('Степень сжатия:'),
                                Slider(
                                  value: _compressionQuality.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  label: _compressionQuality.toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _compressionQuality = value.toInt();
                                    });
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: _compressImage,
                                  child: Text('Сжать изображения'),
                                ),
                                if (_isCompressed) ...[
                                  ElevatedButton(
                                    onPressed: _downloadAllImages,
                                    child: Text('Скачать архивом'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      for (var image in _selectedImages) {
                                        if (image['compressedBytes'] != null) {
                                          _downloadImage(image['compressedBytes'], 'compressed_${image['name']}');
                                        }
                                      }
                                    },
                                    child: Text('Скачать по одному'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
