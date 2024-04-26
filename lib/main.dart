import 'package:flutter/material.dart';
import 'package:generativeai/textandimagemodel/ImageChatHomepage.dart';
import 'package:generativeai/textonlymodel/TextChatHomepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instant Generative AI', // Set dark theme
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ThemeMode _themeMode = ThemeMode.light; // Initialize theme mode to light
  bool _isvisionmodel = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant Generative AI',
      theme: ThemeData.light(), // Set default theme to light mode
      darkTheme: ThemeData.dark(), // Set dark theme
      themeMode: _themeMode, // Use the selected theme mode

      home: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                ),
                child: _isvisionmodel
                    ? const Center(
                        child: Text(
                          "Image and Text Model",
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Text only Model",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
              ),
              ListTile(
                title: _isvisionmodel
                    ? const Text("Switch to Text Only Model")
                    : const Text("Switch to Image and Text Model"),
                onTap: () {
                  setState(() {
                    _isvisionmodel = !_isvisionmodel;
                  });
                },
              ),

              //at last some more option like exit and about us
              ListTile(
                title: const Text("About Us"),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("Exit"),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text('Instant Generative AI'),
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb),
              onPressed: () {
                // Toggle between light and dark mode
                setState(() {
                  _themeMode = _themeMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                });
              },
            ),
          ],
        ),
        body: _isvisionmodel ? const Imagechatwidget() : const Textchatwidget(),
      ),
    );
  }
}
