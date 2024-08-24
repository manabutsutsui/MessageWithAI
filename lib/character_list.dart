import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'character_detail_edit.dart';
import 'ad_banner.dart';

class CharacterListScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> characters;

  const CharacterListScreen({super.key, required this.characters});

  Future<void> _deleteCharacter(BuildContext context, String characterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('キャラクター削除'),
          content: const Text('このキャラクターを削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('characters').doc(characterId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('キャラクターが削除されました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編集するキャラクターを選択'),
      ),
      body: Column(
        children: [
          const AdBanner(),
          Expanded(
            child: ListView.builder(
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(character['imageUrl']),
                  ),
                  title: Text(character['name']),
                  subtitle: Text('${character['age']}歳'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCharacter(context, characters[index].id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CharacterDetailEditScreen(
                          characterId: characters[index].id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SafeArea(
            child: AdBanner(),
          ),
        ],
      ),
    );
  }
}