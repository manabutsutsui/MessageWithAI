import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'character_detail.dart';
import 'ad_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final TextEditingController _textController = TextEditingController();
  String _characterImageUrl = '';
  bool _isGenerating = false;
  String _apiKey = '';
  String _subscriptionPlan = 'free_plan';
  int _generateCount = 0;
  int _generateLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadSubscriptionPlan();
  }

  Future<void> _loadApiKey() async {
    final config = await rootBundle.loadString('assets/config.json');
    final configData = jsonDecode(config);
    setState(() {
      _apiKey = configData['openaiApiKey'];
    });
  }

  Future<void> _loadSubscriptionPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString('subscriptionPlan') ?? 'free_plan';
    setState(() {
      _subscriptionPlan = plan;
      _generateLimit = _getGenerateLimit(plan);
    });
  }

  int _getGenerateLimit(String plan) {
    switch (plan) {
      case 'standard_monthly_subscription':
        return 20;
      case 'premium_monthly_subscription':
        return -1; // 無制限
      default:
        return 10;
    }
  }

  Future<void> _generateCharacterImage(String description) async {
    if (_subscriptionPlan != 'premium_monthly_subscription' && _generateCount >= _generateLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像生成回数が上限に達しました。プランを変更してください。')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    const apiUrl = 'https://api.openai.com/v1/images/generations';

    final enhancedPrompt =
        '高品質な、$description。魅力的な一人のクローズアップ画像。背景はシンプルで、他の人物や顔が含まれないようにしてください。そして、画面中央に一人の人物のみを表示してください';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': enhancedPrompt,
          'n': 1,
          'size': '1024x1024',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _characterImageUrl = data['data'][0]['url'];
          _generateCount++;
        });
        _saveGenerateCount();
      } else {
        print('画像生成に失敗しました: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像生成に失敗しました}')),
        );
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }

    setState(() {
      _isGenerating = false;
    });
  }

  Future<void> _saveGenerateCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('generateCount', _generateCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター作成'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AdBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text('キャラクターの画像をAIで生成します。'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: _isGenerating
                          ? const CircularProgressIndicator()
                          : _characterImageUrl.isNotEmpty
                              ? Image.network(_characterImageUrl, fit: BoxFit.contain)
                              : const Icon(Icons.image, size: 200, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '例: 着物を着た大人の女性',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_textController.text.isNotEmpty) {
                        _generateCharacterImage(_textController.text);
                      }
                    },
                    child: const Text('生成'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_characterImageUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterDetailScreen(
                              imageUrl: _characterImageUrl,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('先に画像を生成してください。'),
                          ),
                        );
                      }
                    },
                    child: const Text('次へ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}