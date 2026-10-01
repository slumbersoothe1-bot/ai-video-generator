import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'external_link.dart';

class YouTubeTrendingScreen extends StatefulWidget {
  const YouTubeTrendingScreen({super.key});
  @override
  State<YouTubeTrendingScreen> createState() => _YouTubeTrendingScreenState();
}

class _YouTubeTrendingScreenState extends State<YouTubeTrendingScreen> {
  String? _region;
  bool _loading = false;
  String? _error;
  String? _fetched;
  List<dynamic> _items = [];
  Future<void> _load() async {
    if (_region == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });
    try {
      final response = await ApiClient.instance()
          .get('/youtube-trending', queryParameters: {'region': _region});
      final data = response.data as Map<String, dynamic>;
      if (mounted)
        setState(() {
          _items = data['items'] as List<dynamic>? ?? [];
          _fetched = data['fetched_at']?.toString();
        });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'YouTube popular videos are not available yet. The server API key and deployment must be connected, and the chart must be available for this region. No demo trends are shown.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('YouTube popular videos')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text(
              'YouTube mostPopular chart, not trends across all platforms. Choose your audience region. Data may be cached for up to one hour.'),
          DropdownButtonFormField<String>(
              value: _region,
              hint: const Text('Choose region'),
              items: const [
                DropdownMenuItem(value: 'US', child: Text('United States (English)')),
                DropdownMenuItem(value: 'GB', child: Text('United Kingdom (English)')),
                DropdownMenuItem(value: 'EG', child: Text('Egypt (Arabic)')),
                DropdownMenuItem(value: 'SA', child: Text('Saudi Arabia (Arabic)')),
                DropdownMenuItem(value: 'AE', child: Text('United Arab Emirates (Arabic)')),
                DropdownMenuItem(value: 'FR', child: Text('France (French)')),
                DropdownMenuItem(value: 'ES', child: Text('Spain (Spanish)')),
                DropdownMenuItem(value: 'DE', child: Text('Germany (German)')),
                DropdownMenuItem(value: 'BR', child: Text('Brazil (Portuguese)')),
                DropdownMenuItem(value: 'PT', child: Text('Portugal (Portuguese)')),
                DropdownMenuItem(value: 'IN', child: Text('India (Hindi)')),
                DropdownMenuItem(value: 'TR', child: Text('Turkey (Turkish)')),
                DropdownMenuItem(value: 'ID', child: Text('Indonesia (Indonesian)')),
                DropdownMenuItem(value: 'KR', child: Text('South Korea (Korean)')),
                DropdownMenuItem(value: 'JP', child: Text('Japan (Japanese)')),
                DropdownMenuItem(value: 'TW', child: Text('Taiwan (Chinese)')),
                DropdownMenuItem(value: 'HK', child: Text('Hong Kong (Chinese)')),
              ],
              onChanged: (v) => setState(() {
                    _region = v;
                    _items = [];
                    _fetched = null;
                  })),
          TextButton(
              onPressed: _region == null || _loading ? null : _load,
              child: Text(_loading ? 'Loading...' : 'Load YouTube chart')),
          if (_error != null) Text(_error!),
          if (_fetched != null) Text('Source: YouTube. Fetched: $_fetched'),
          for (final item in _items)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['thumbnail'] != null)
                            Image.network(item['thumbnail'].toString(),
                                height: 150,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.video_library)),
                          Text(item['title']?.toString() ?? 'YouTube video'),
                          Text(item['channel']?.toString() ?? ''),
                          TextButton(
                              onPressed: () =>
                                  openExternal(item['url'].toString()),
                              child: const Text('Watch on YouTube')),
                        ]))),
          const SizedBox(height: 16),
          const Text(
              'Watching a popular video does not give permission to reuse its footage or music.'),
        ]),
      );
}
