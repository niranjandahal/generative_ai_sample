import 'dart:io';
import 'package:flutter/material.dart';
import 'package:generativeai/api/gemini_apikey.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Imagechatwidget extends StatefulWidget {
  const Imagechatwidget({
    super.key,
  });

  @override
  State<Imagechatwidget> createState() => _ImagechatwidgetState();
}

class _ImagechatwidgetState extends State<Imagechatwidget> {
  //initilization
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _generatedContent =
      <({Image? image, String? text, bool fromUser})>[];

  //loading state
  bool _loading = false;

  //initfunction
  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apikey);
    _visionModel = GenerativeModel(
      model: 'gemini-pro-vision',
      apiKey: apikey,
    );
    _chat = _model.startChat();
  }

  //other function
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendImagePrompt(String message) async {
    setState(() {
      _loading = true;
    });
    try {
      final ImagePicker picker = ImagePicker();
      // Show options for the user to select image from gallery or capture from camera
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                GestureDetector(
                  child: const Row(
                    children: [
                      Icon(Icons.photo_library),
                      SizedBox(width: 20),
                      Text('Gallery'),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    child: const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 20),
                        Text('Camera'),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final XFile? image = await picker.pickImage(source: source);
      if (image == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final ByteData bytes =
          await image.readAsBytes().then((bytes) => bytes.buffer.asByteData());
      final content = [
        Content.multi([
          TextPart(message),
          DataPart('image/jpeg', bytes.buffer.asUint8List()),
        ])
      ];
      _generatedContent.add(
          (image: Image.file(File(image.path)), text: message, fromUser: true));
      var response = await _visionModel.generateContent(content);
      var text = response.text;
      _generatedContent.add((image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      // _textFieldFocus.requestFocus();
    }
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      _generatedContent.add((image: null, text: message, fromUser: true));
      final response = await _chat.sendMessage(
        Content.text(message),
      );
      final text = response.text;
      _generatedContent.add((image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      // _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  List<String> Sampleprompts = [
    "Ask me about the impact of renewable energy on the environment 🌱🔋",
    "Need recommendations for healthy recipes or dietary tips? I've got you covered! 🥗🍎",
    "Want insights into space exploration and colonization?🚀🌌"
  ];

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _generatedContent.isEmpty // Check if there are no messages
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //display 3 sampleprompts in very beautiful shiny cards
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Card(
                                child: ListTile(
                                  onTap: () {
                                    _textController.text = Sampleprompts[0];
                                    _sendChatMessage(Sampleprompts[0]);
                                    _textController.clear();
                                  },
                                  subtitle: Text(Sampleprompts[0]),
                                  title: const Text('Renewable Energy'),
                                  leading: const Icon(Icons.eco),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: ListTile(
                                  onTap: () {
                                    _textController.text = Sampleprompts[1];
                                    _sendChatMessage(Sampleprompts[1]);
                                    _textController.clear();
                                  },
                                  subtitle: Text(Sampleprompts[1]),
                                  title: const Text('Healthy Recipes'),
                                  leading: const Icon(Icons.food_bank),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // Action when the user clicks the button
                                },
                                child: const Text('Ask Me Anything'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final content = _generatedContent[index];
                      return MessageWidget(
                        text: content.text,
                        image: content.image,
                        isFromUser: content.fromUser,
                      );
                    },
                    itemCount: _generatedContent.length,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 1,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: !_loading
                      ? () async {
                          _sendImagePrompt(_textController.text);
                          _textController.clear();
                        }
                      : null,
                  icon: Icon(
                    Icons.image_search_sharp,
                    color: _loading
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    autofocus: false,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox.square(dimension: 15),
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      _sendChatMessage(_textController.text);
                      _textController.clear();
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const SizedBox(
                    height: 25,
                    width: 25,
                    // color: Colors.red,
                    child: LoadingIndicator(
                        indicatorType: Indicator.ballPulse,
                        colors: [Colors.blue, Colors.amber, Colors.pink],

                        /// Optional, The color collections
                        strokeWidth: 1,

                        /// Optional, The stroke of the line, only applicable to widget which contains line
                        backgroundColor: Colors.transparent,

                        /// Optional, Background of the widget
                        pathBackgroundColor: Colors.yellow),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  if (text case final text?) MarkdownBody(data: text),
                  if (image case final image?) image,
                ]))),
      ],
    );
  }
}
