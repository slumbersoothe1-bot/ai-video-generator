// Browser-native media tools. No uploads, paid services, or AI generation.
// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class MediaToolsScreen extends StatefulWidget {
  const MediaToolsScreen({super.key, this.initialUrl});
  final String? initialUrl;
  @override
  State<MediaToolsScreen> createState() => _MediaToolsScreenState();
}

class _MediaToolsScreenState extends State<MediaToolsScreen> {
  final _url = TextEditingController();
  final _script = TextEditingController();
  final _video = html.VideoElement()..controls = true;
  final _audio = html.AudioElement()..controls = true;
  late final String _videoView;
  late final String _audioView;
  String? _videoUrl;
  String? _musicUrl;
  String _fileName = 'video.mp4';
  String? _status;
  bool _localVideo = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final id = DateTime.now().microsecondsSinceEpoch;
    _videoView = 'media-video-$id';
    _audioView = 'media-audio-$id';
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = '#000';
    _audio.style.width = '100%';
    ui.platformViewRegistry.registerViewFactory(_videoView, (_) => _video);
    ui.platformViewRegistry.registerViewFactory(_audioView, (_) => _audio);
    _video.onError.listen((_) {
      if (mounted)
        setState(() => _status =
            'This video could not be played. Check the format and link permissions.');
    });
    if (widget.initialUrl != null) {
      _url.text = widget.initialUrl!;
      _loadUrl();
    }
  }

  bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  void _loadUrl() {
    final value = _url.text.trim();
    if (!_validUrl(value)) {
      setState(() => _status =
          'Use a direct HTTPS video link, not a social post or watch-page link.');
      return;
    }
    _replaceVideo(value, false, 'video.mp4');
  }

  void _replaceVideo(String value, bool local, String name) {
    _video.pause();
    if (_localVideo && _videoUrl != null) html.Url.revokeObjectUrl(_videoUrl!);
    _video.src = value;
    _video.load();
    setState(() {
      _videoUrl = value;
      _localVideo = local;
      _fileName = name;
      _status = local
          ? 'Local video loaded. Nothing was uploaded.'
          : 'Link loaded. The source controls playback and downloads.';
    });
  }

  void _pick(bool music) {
    final picker = html.FileUploadInputElement()
      ..accept = music ? 'audio/*' : 'video/*';
    picker.onChange.first.then((_) {
      if (!mounted || picker.files == null || picker.files!.isEmpty) return;
      final file = picker.files!.first;
      final url = html.Url.createObjectUrl(file);
      if (music) {
        _audio.pause();
        if (_musicUrl != null) html.Url.revokeObjectUrl(_musicUrl!);
        _audio.src = url;
        setState(() {
          _musicUrl = url;
          _status =
              'Music loaded for separate playback. It is not mixed into the video.';
        });
      } else {
        _replaceVideo(url, true, file.name);
      }
    });
    picker.click();
  }

  Future<void> _download() async {
    if (_videoUrl == null || _busy) return;
    if (_localVideo) {
      (html.AnchorElement(href: _videoUrl)..download = _fileName).click();
      setState(() => _status =
          'Download requested for the original file, not an edited video.');
      return;
    }
    setState(() => _busy = true);
    try {
      final response =
          await html.HttpRequest.request(_videoUrl!, responseType: 'blob');
      final blob = response.response as html.Blob;
      final url = html.Url.createObjectUrl(blob);
      (html.AnchorElement(href: url)..download = _fileName).click();
      Future.delayed(
          const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
      if (mounted)
        setState(() =>
            _status = 'Download requested. Check your browser downloads.');
    } catch (_) {
      if (mounted)
        setState(() => _status =
            'The source did not allow this download. Use Open video and its own download controls if available.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _speak() {
    final text = _script.text.trim();
    if (text.isEmpty) {
      setState(() => _status = 'Enter text to read aloud.');
      return;
    }
    try {
      final speech = html.window.speechSynthesis;
      if (speech == null) {
        setState(() => _status = 'Speech is not supported by this browser.');
        return;
      }
      if (speech.getVoices().isEmpty) {
        setState(() => _status =
            'No browser voices are available. Try a browser or device with speech voices installed.');
        return;
      }
      speech.cancel();
      speech.speak(html.SpeechSynthesisUtterance(text));
      setState(() => _status =
          'Reading aloud with your browser voice. This does not create or export an audio file.');
    } catch (_) {
      setState(() => _status = 'Speech is unavailable in this browser.');
    }
  }

  @override
  void dispose() {
    _video.pause();
    _audio.pause();
    html.window.speechSynthesis?.cancel();
    if (_localVideo && _videoUrl != null) html.Url.revokeObjectUrl(_videoUrl!);
    if (_musicUrl != null) html.Url.revokeObjectUrl(_musicUrl!);
    _url.dispose();
    _script.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Media tools')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text(
              'Use a video you already own. No AI video is created, and local files are not uploaded.'),
          const SizedBox(height: 16),
          TextField(
              controller: _url,
              decoration:
                  const InputDecoration(labelText: 'Direct HTTPS video link')),
          Wrap(spacing: 8, children: [
            TextButton(onPressed: _loadUrl, child: const Text('Load link')),
            TextButton(
                onPressed: () => _pick(false),
                child: const Text('Choose local video')),
          ]),
          if (_videoUrl != null) ...[
            SizedBox(height: 230, child: HtmlElementView(viewType: _videoView)),
            Wrap(spacing: 8, children: [
              TextButton(
                  onPressed: _busy ? null : _download,
                  child: Text(_busy ? 'Downloading...' : 'Download original')),
              if (!_localVideo)
                TextButton(
                    onPressed: () => html.window.open(_videoUrl!, '_blank'),
                    child: const Text('Open video')),
              if (!_localVideo)
                TextButton(
                    onPressed: () => Share.share(_videoUrl!),
                    child: const Text('Share link')),
              if (!_localVideo)
                TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _videoUrl!));
                      if (mounted)
                        setState(() => _status = 'Video link copied.');
                    },
                    child: const Text('Copy link')),
            ]),
          ],
          const SizedBox(height: 16),
          Text('Voice read-aloud',
              style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Browser voice preview only. Not a recorded voiceover or a video export. Available voices depend on your device.'),
          TextField(
              controller: _script,
              minLines: 2,
              maxLines: 6,
              decoration:
                  const InputDecoration(labelText: 'Text to read aloud')),
          Wrap(spacing: 8, children: [
            TextButton(onPressed: _speak, child: const Text('Read aloud')),
            TextButton(
                onPressed: () => html.window.speechSynthesis?.cancel(),
                child: const Text('Stop voice')),
          ]),
          const SizedBox(height: 16),
          Text('Free music', style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Feel Good Summer Tune by skrjablin. CC0: commercial use permitted; attribution not required, credit appreciated. Music plays separately and is not mixed into your video.'),
          TextButton(
              onPressed: () {
                _audio.src =
                    'https://opengameart.org/sites/default/files/feel_good_summer_tune.ogg';
                setState(() {
                  _musicUrl =
                      'https://opengameart.org/sites/default/files/feel_good_summer_tune.ogg';
                  _status =
                      'CC0 track loaded. Use its player controls to listen.';
                });
              },
              child: const Text('Load free summer track')),
          TextButton(
              onPressed: () => html.window.open(
                  'https://opengameart.org/content/feel-good-summer-tune',
                  '_blank'),
              child: const Text('Track source and download')),
          TextButton(
              onPressed: () => html.window.open(
                  'https://creativecommons.org/publicdomain/zero/1.0/',
                  '_blank'),
              child: const Text('Read CC0 license')),
          Text('Your music', style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Choose audio you have permission to use. Playback is separate; this does not add music to a video or provide a music license.'),
          TextButton(
              onPressed: () => _pick(true),
              child: const Text('Choose local audio')),
          if (_musicUrl != null)
            SizedBox(height: 60, child: HtmlElementView(viewType: _audioView)),
          const SizedBox(height: 16),
          if (_status != null) Text(_status!),
          const SizedBox(height: 16),
          const Text(
              'Auto-posting and live trend data are not connected. Share manually. Exporting a video with voice or music is not available.'),
        ]),
      );
}
