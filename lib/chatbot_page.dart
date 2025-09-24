import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, String>> messages = [];
  final TextEditingController controller = TextEditingController();
  bool isTyping = false;

  Future<void> getBotReply(String userMessage) async {
  try {
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_API_KEY_HERE",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": userMessage},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['choices'] != null && data['choices'].isNotEmpty) {
        final botReply = data['choices'][0]['message']['content'];
        setState(() {
          messages.add({"role": "bot", "text": botReply});
        });
      } else {
        setState(() {
          messages.add({"role": "bot", "text": "⚠️ Sorry, I couldn't get a reply."});
        });
      }
    } else {
      setState(() {
        messages.add({"role": "bot", "text": "⚠️ API Error: ${response.statusCode}"});
      });
    }
  } catch (e) {
    setState(() {
      messages.add({"role": "bot", "text": "⚠️ Error: $e"});
    });
  }
}

  void sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  setState(() {
    messages.add({"role": "user", "text": text});
    isTyping = true;
  });
  controller.clear();

  await getBotReply(text);

  setState(() {
    isTyping = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BusSeva Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg["role"] == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["role"] == "user"
                          ? Colors.blueAccent
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: msg["role"] == "user"
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Bot is typing...", style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about buses, routes...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => sendMessage(controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
