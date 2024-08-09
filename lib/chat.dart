import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'character_detail_edit.dart';
import 'package:flutter/services.dart' show rootBundle;

class CharacterVoiceChatScreen extends StatefulWidget {
  final String name;
  final int age;
  final String personality;
  final String imageUrl;
  final String characterId;

  const CharacterVoiceChatScreen({
    super.key,
    required this.name,
    required this.age,
    required this.personality,
    required this.imageUrl,
    required this.characterId,
  });

  @override
  CharacterVoiceChatScreenState createState() =>
      CharacterVoiceChatScreenState();
}

class CharacterVoiceChatScreenState extends State<CharacterVoiceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadMessages();
  }

  Future<void> _loadApiKey() async {
    final config = await rootBundle.loadString('assets/config.json');
    final configData = jsonDecode(config);
    setState(() {
      _apiKey = configData['openaiApiKey'];
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userMessage = _messageController.text;
      setState(() {
        _messages.add(Message(text: userMessage, isUser: true));
        _messageController.clear();
        _isTyping = true;
      });

      final response = await _getAIResponse(userMessage);

      setState(() {
        _messages.add(Message(text: response, isUser: false));
        _isTyping = false;
      });

      _saveMessages();
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    const apiUrl = 'https://api.openai.com/v1/chat/completions';

    // 過去のメッセージを含める
    final messages = [
      {
        'role': 'system',
        'content': '${widget.name}として振る舞ってください。${widget.age}歳で、${widget.personality}性格です。画像URLは${widget.imageUrl}です。'
      },
      ..._messages.map((message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'Accept-Charset': 'utf-8',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      return 'エラーが発生しました。もう一度お試しください。';
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = _messages.map((message) => jsonEncode(message.toJson())).toList();
    await prefs.setStringList('messages_${widget.name}', messages);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList('messages_${widget.name}') ?? [];
    setState(() {
      _messages.addAll(messages.map((message) => Message.fromJson(jsonDecode(message))));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterDetailEditScreen(characterId: widget.characterId),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(widget.imageUrl),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(message: message, imageUrl: widget.imageUrl);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text('${widget.name}が入力中...'),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'メッセージを入力',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
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

class Message {
  final String text;
  final bool isUser;
  final bool isSystem;

  Message({required this.text, required this.isUser, this.isSystem = false});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'isSystem': isSystem,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        isSystem: json['isSystem'],
      );
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final String imageUrl;

  const MessageBubble({super.key, required this.message, required this.imageUrl});

  @override
  Widget build(BuildContext context) {

    return Align(
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                        ? Colors.blue[100]
                        : Colors.green[100],
                borderRadius: BorderRadius.only(
                  topLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(0),
                  topRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.black),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}