import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:generativeai/api/gemini_apikey.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Textchatwidget extends StatefulWidget {
  const Textchatwidget({
    Key? key,
  }) : super(key: key);
  @override
  _TextchatwidgetState createState() => _TextchatwidgetState();
}

class _TextchatwidgetState extends State<Textchatwidget> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apikey);
    _chat = _model.startChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(text);
    });
    try {
      final response = _chat.sendMessageStream(
        Content.text(text),
      );
      String generatedText = '';
      await for (final chunk in response) {
        for (int i = 0; i < chunk.text!.length; i++) {
          generatedText += chunk.text![i];
          setState(() {
            _messages[_messages.length - 1] = generatedText;
          });
          await Future.delayed(
              Duration(milliseconds: 5)); // Adjust the speed here
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: MessageWidget(
                  text: message,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter your message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    _sendMessage(value.trim());
                    _textController.clear();
                  },
                ),
              ),
              SizedBox(width: 8.0),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    _sendMessage(text);
                    _textController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    this.text,
  });

  final String? text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
            child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  if (text case final text?) MarkdownBody(data: text),
                ]))),
      ],
    );
  }
}
