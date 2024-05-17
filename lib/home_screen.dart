import 'package:flutter/material.dart';
import 'compression_screen.dart';
import 'conversion_screen.dart';

class HomeScreen extends StatelessWidget {
  void _navigateToCompression(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CompressionScreen()),
    );
  }

  void _navigateToConversion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConversionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToCompression(context),
              child: Text('Сжать изображения'),
            ),
            ElevatedButton(
              onPressed: () => _navigateToConversion(context),
              child: Text('Конвертировать изображения'),
            ),
          ],
        ),
      ),
    );
  }
}
