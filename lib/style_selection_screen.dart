import 'package:flutter/material.dart';
import 'processing_screen.dart';
import 'dart:io';

final List<String> images = [
  'assets/images/anime_style.png',
  'assets/images/watercolor_style.png',
  'assets/images/fantastic_style.png',
  'assets/images/3d_style.png',
];

class StyleSelectionScreen extends StatefulWidget {
  final File image;

  const StyleSelectionScreen({super.key, required this.image});

  @override
  StyleSelectionScreenState createState() => StyleSelectionScreenState();
}

class StyleSelectionScreenState extends State<StyleSelectionScreen> {
  String? selectedStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Style', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                widget.image,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Please select a style to apply ✨',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildStyleButton(context, images[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: selectedStyle != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProcessingScreen(
                                  image: widget.image,
                                  selectedStyle: _getStyleName(selectedStyle!),
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleButton(BuildContext context, String imagePath) {
    String styleName = _getStyleName(imagePath);
    bool isSelected = selectedStyle == imagePath;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStyle = imagePath;
        });
      },
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Center(
              child: Text(
                styleName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStyleName(String imagePath) {
    switch (imagePath) {
      case 'assets/images/anime_style.png':
        return 'anime';
      case 'assets/images/watercolor_style.png':
        return 'watercolor';
      case 'assets/images/fantastic_style.png':
        return 'fantastic';
      case 'assets/images/3d_style.png':
        return '3D';
      default:
        return '';
    }
  }
}