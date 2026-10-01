// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
class PhotoVideoMakerScreen extends StatefulWidget {
  const PhotoVideoMakerScreen({super.key});
  @override
  State<PhotoVideoMakerScreen> createState() => _PhotoVideoMakerScreenState();
}
class _PhotoVideoMakerScreenState extends State<PhotoVideoMakerScreen> {
  late final String _view;
  @override
  void initState() {
    super.initState();
    _view='photo-maker-${DateTime.now().microsecondsSinceEpoch}';
    ui.platformViewRegistry.registerViewFactory(_view, (_) => html.IFrameElement()..src='photo_video_maker.html'..style.border='0'..style.width='100%'..style.height='100%');
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Photo video maker')), body: HtmlElementView(viewType: _view));
}
