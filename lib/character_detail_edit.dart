import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CharacterDetailEditScreen extends StatefulWidget {
  final String characterId;

  const CharacterDetailEditScreen({super.key, required this.characterId});

  @override
  CharacterDetailEditScreenState createState() => CharacterDetailEditScreenState();
}

class CharacterDetailEditScreenState extends State<CharacterDetailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _personalityController;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _personalityController = TextEditingController();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('characters')
        .doc(widget.characterId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _personalityController.text = data['personality'] ?? '';
        _imageUrl = data['imageUrl'] ?? '';
      });
    }
  }

  Future<void> _updateCharacter() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('characters')
            .doc(widget.characterId)
            .update({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'personality': _personalityController.text,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新が完了しました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新中にエラーが発生しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター編集'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(
              height: 200,
              child: _imageUrl.isNotEmpty
                  ? Image.network(_imageUrl, fit: BoxFit.contain)
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _personalityController,
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
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateCharacter,
              child: const Text('更新'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _personalityController.dispose();
    super.dispose();
  }
}