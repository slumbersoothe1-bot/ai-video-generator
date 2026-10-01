import 'package:flutter/material.dart';

class PhotoVideoMakerScreen extends StatelessWidget {
  const PhotoVideoMakerScreen({super.key, this.initialText, this.templateName});
  final String? initialText;
  final String? templateName;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Photo video maker')),
      body:
          const Center(child: Text('Open the web app to make a photo video.')));
}
