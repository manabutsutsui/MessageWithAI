import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'style_selection_screen.dart';
import 'utils/ad_native.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'StyleShift: AI Photo Transformer',
      theme: themeProvider.isDarkMode ? ThemeData.light() : ThemeData.dark(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StyleSelectionScreen(image: _image!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleShift: AI Photo Transformer', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.image,
              size: MediaQuery.of(context).size.height * 0.3,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('Select a photo to apply style ✨'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text('Choose Photo', style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo', style: TextStyle(decoration: TextDecoration.underline),),
            ),
            const SizedBox(height: 8),
            const NativeAdWidget(),
          ],
        ),
      ),
    );
  }
}