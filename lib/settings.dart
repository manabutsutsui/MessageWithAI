import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'character_list.dart';
import 'ad_banner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ListTile(
                  title: const Text('ダークモード'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('キャラクター編集'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final characters = await FirebaseFirestore.instance
                        .collection('characters')
                        .where('deviceId', isEqualTo: await _getDeviceId())
                        .get();
                    if (characters.docs.isNotEmpty) {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterListScreen(
                              characters: characters.docs,
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('編集可能なキャラクターがありません')),
                      );
                    }
                  },
                ),
                const Divider(),
                const AdBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}