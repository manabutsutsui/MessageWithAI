import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';
import 'main.dart';

class CharacterDetailScreen extends StatefulWidget {
  final String imageUrl;
  const CharacterDetailScreen({super.key, required this.imageUrl});

  @override
  CharacterDetailScreenState createState() => CharacterDetailScreenState();
}

class CharacterDetailScreenState extends State<CharacterDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int _age = 0;
  String _personality = '';
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    setState(() {
      _deviceId = iosInfo.identifierForVendor ?? '';
    });
  }

  Future<void> _saveCharacterToFirestore() async {
    try {
      // Firebase Storageに画像をアップロード
      final String fileName =
          'characters/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      // URLから画像データを取得
      final response = await http.get(Uri.parse(widget.imageUrl));
      final Uint8List imageData = response.bodyBytes;

      // 画像データをアップロード
      final UploadTask uploadTask = storageRef.putData(imageData);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestoreにデータを保存
      await FirebaseFirestore.instance.collection('characters').add({
        'name': _name,
        'age': _age,
        'personality': _personality,
        'imageUrl': downloadUrl,
        'deviceId': _deviceId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('キャラクター情報がFirestoreに保存されました')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      print('エラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター詳細'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(
              height: 200,
              child: Image.network(widget.imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '名前を入力してください';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '年齢',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '年齢を入力してください';
                }
                if (int.tryParse(value) == null) {
                  return '有効な数字を入力してください';
                }
                return null;
              },
              onSaved: (value) {
                _age = int.parse(value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '性格、趣味',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '性格を入力してください';
                }
                return null;
              },
              onSaved: (value) {
                _personality = value!;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _saveCharacterToFirestore();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}