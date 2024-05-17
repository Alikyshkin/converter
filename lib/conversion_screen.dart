import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive_io.dart';
import 'image_widgets.dart';

class ConversionScreen extends StatefulWidget {
  @override
  _ConversionScreenState createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  List<Map<String, dynamic>> _selectedImages = [];
  bool _isConverting = false;
  bool _isConverted = false;
  String _targetFormat = 'jpg';

  final List<String> _supportedFormats = ['jpg', 'png', 'gif', 'bmp', 'tiff'];

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
            if (!['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff'].contains(extension)) {
              print('Формат $extension не поддерживается');
              return;
            }
            setState(() {
              _selectedImages.add({
                'name': file.name,
                'originalBytes': imageData,
                'convertedBytes': null,
                'originalSize': file.size,
                'convertedSize': null,
                'originalExtension': extension,
                'convertedExtension': null
              });
            });
          });
        }
      }
    });
  }

  void _convertImages() async {
    setState(() {
      _isConverting = true;
    });

    await Future.delayed(Duration(seconds: 2)); // Имитируем время на конвертацию изображений

    for (var image in _selectedImages) {
      final img.Image? decodedImage = img.decodeImage(image['originalBytes']);
      if (decodedImage != null) {
        Uint8List convertedBytes;
        switch (_targetFormat) {
          case 'png':
            convertedBytes = Uint8List.fromList(img.encodePng(decodedImage));
            break;
          case 'gif':
            convertedBytes = Uint8List.fromList(img.encodeGif(decodedImage));
            break;
          case 'bmp':
            convertedBytes = Uint8List.fromList(img.encodeBmp(decodedImage));
            break;
          case 'tiff':
            convertedBytes = Uint8List.fromList(img.encodeTga(decodedImage)); // Используем TGA вместо TIFF
            break;
          case 'jpg':
          default:
            convertedBytes = Uint8List.fromList(img.encodeJpg(decodedImage));
        }
        setState(() {
          image['convertedBytes'] = convertedBytes;
          image['convertedSize'] = convertedBytes.length;
          image['convertedExtension'] = _targetFormat;
        });
      }
    }

    setState(() {
      _isConverting = false;
      _isConverted = true;
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
        if (image['convertedBytes'] != null) {
          archive.addFile(ArchiveFile(image['name'], image['convertedBytes'].length, image['convertedBytes']));
        }
      }
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      final blob = html.Blob([zipData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "converted_images.zip")
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
                  _isConverted = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isConverted
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: _clearImages,
              )
            : null,
        title: Text('Конвертация изображений'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: _isConverting
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Конвертация изображений...'),
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
                                    leading: Image.memory(image['convertedBytes'] ?? image['originalBytes']),
                                    title: Text(image['name']),
                                    subtitle: Text(
                                      'Изначальный размер: ${image['originalSize']} байт\n'
                                      'Конвертированный размер: ${image['convertedSize'] ?? 'Не конвертировано'} байт\n'
                                      'Изначальный формат: ${image['originalExtension']}\n'
                                      'Конвертированный формат: ${image['convertedExtension'] ?? 'Не конвертировано'}',
                                    ),
                                    trailing: image['convertedBytes'] != null
                                        ? IconButton(
                                            icon: Icon(Icons.download),
                                            onPressed: () => _downloadImage(image['convertedBytes'], 'converted_${image['name']}.${image['convertedExtension']}'),
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
                                DropdownButton<String>(
                                  value: _targetFormat,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _targetFormat = newValue!;
                                    });
                                  },
                                  items: _supportedFormats
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.toUpperCase()),
                                    );
                                  }).toList(),
                                  isExpanded: true,
                                ),
                                ElevatedButton(
                                  onPressed: _convertImages,
                                  child: Text('Конвертировать изображения'),
                                ),
                                if (_isConverted) ...[
                                  ElevatedButton(
                                    onPressed: _downloadAllImages,
                                    child: Text('Скачать архивом'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      for (var image in _selectedImages) {
                                        if (image['convertedBytes'] != null) {
                                          _downloadImage(image['convertedBytes'], 'converted_${image['name']}.${image['convertedExtension']}');
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
