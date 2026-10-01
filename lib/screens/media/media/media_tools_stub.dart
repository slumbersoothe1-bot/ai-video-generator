import 'package:flutter/material.dart';

class MediaToolsScreen extends StatelessWidget {
  const MediaToolsScreen({super.key, this.initialUrl});
  final String? initialUrl;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Media tools')),
        body: const Center(
            child: Text('These media tools are available in the web app.')),
      );
}
