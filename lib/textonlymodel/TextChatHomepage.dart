import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:generativeai/api/gemini_apikey.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_indicator/loading_indicator.dart';

class Textchatwidget extends StatefulWidget {
  const Textchatwidget({
    super.key,
  });
  @override
  _TextchatwidgetState createState() => _TextchatwidgetState();
}

class _TextchatwidgetState extends State<Textchatwidget> {
  final ScrollController _scrollController = ScrollController();
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apikey);
    _chat = _model.startChat();
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 5),
      curve: Curves.easeOutCirc,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _loading = true;
      _messages.add(text);
    });
    try {
      final response = _chat.sendMessageStream(
        Content.text(text),
      );
      String generatedText = '';
      _messages.add('');
      await for (final chunk in response) {
        for (int i = 0; i < chunk.text!.length; i++) {
          generatedText += chunk.text![i];
        }
        setState(() {
          _loading = false;
          _messages[_messages.length - 1] = generatedText;
        });
        _scrollDown(); // Scroll down after updating the UI
        await Future.delayed(const Duration(milliseconds: 1));

        _scrollDown();
      }
    } catch (e) {
      // print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _messages.isEmpty
            ? const Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Start chatting with the AI',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      SizedBox(
                          height: 20,
                          width: 20,
                          child: LoadingIndicator(
                            indicatorType: Indicator.ballPulseSync,
                            colors: [
                              Colors.blue,
                              Colors.red,
                              Colors.yellow,
                            ],
                          ))
                    ],
                  ),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: MessageWidget(
                        text: message,
                      ),
                    );
                  },
                ),
              ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onSubmitted: (value) {
                    _sendMessage(value.trim());
                    _textController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              if (_loading)
                const SizedBox(
                  height: 30,
                  width: 30,
                  child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                      colors: [Colors.blue, Colors.red, Colors.yellow]),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send),
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
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Theme.of(context)
          .cardColor, // Use primary color as the background color for the card
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MarkdownBody(
          data: text ?? '',
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer), // Use secondary color for text inside the card
          ),
        ),
      ),
    );
  }
}
