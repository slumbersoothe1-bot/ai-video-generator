/// Lifecycle status of a video generation job.
enum VideoStatus {
  queued,
  processing,
  completed,
  failed,
  unknown;

  factory VideoStatus.fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'queued':
        return VideoStatus.queued;
      case 'processing':
      case 'rendering':
        return VideoStatus.processing;
      case 'completed':
      case 'done':
      case 'success':
        return VideoStatus.completed;
      case 'failed':
      case 'error':
        return VideoStatus.failed;
      default:
        return VideoStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case VideoStatus.queued:
        return 'Queued';
      case VideoStatus.processing:
        return 'Processing';
      case VideoStatus.completed:
        return 'Completed';
      case VideoStatus.failed:
        return 'Failed';
      case VideoStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal =>
      this == VideoStatus.completed || this == VideoStatus.failed;
}

/// A video generation job as returned by the API.
class VideoModel {
  VideoModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.style,
    required this.status,
    this.progress = 0,
    this.thumbnailUrl,
    this.videoUrl,
    this.colorPalette = const [],
    this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      status: VideoStatus.fromString(json['status']?.toString()),
      progress: _parseProgress(json['progress']),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      colorPalette: _parsePalette(json['color_palette']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      errorMessage: json['error_message']?.toString(),
    );
  }

  final String id;
  final String title;
  final String prompt;
  final String style;
  final VideoStatus status;
  final int progress; // 0..100
  final String? thumbnailUrl;
  final String? videoUrl;
  final List<String> colorPalette;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  VideoModel copyWith({
    VideoStatus? status,
    int? progress,
    String? thumbnailUrl,
    String? videoUrl,
    List<String>? colorPalette,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return VideoModel(
      id: id,
      title: title,
      prompt: prompt,
      style: style,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      colorPalette: colorPalette ?? this.colorPalette,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static int _parseProgress(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.toInt().clamp(0, 100);
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll('%', '').trim());
      if (parsed != null) return parsed.toInt().clamp(0, 100);
    }
    return 0;
  }

  static List<String> _parsePalette(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

/// A single caption cue with a start/end timestamp and text.
class CaptionSegment {
  CaptionSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  factory CaptionSegment.fromJson(Map<String, dynamic> json) {
    return CaptionSegment(
      startMs: _parseMs(json['start'] ?? json['start_ms'] ?? json['begin']),
      endMs: _parseMs(json['end'] ?? json['end_ms'] ?? json['finish']),
      text: (json['text'] ?? json['content'] ?? '').toString(),
    );
  }

  final int startMs;
  final int endMs;
  final String text;

  String get formattedStart => _formatTimestamp(startMs);
  String get formattedEnd => _formatTimestamp(endMs);

  static int _parseMs(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Try "00:01.234" style first.
      final ts = _timestampToMs(value);
      if (ts != null) return ts;
      return double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static int? _timestampToMs(String ts) {
    final parts = ts.split(':');
    if (parts.length != 2 && parts.length != 3) return null;
    try {
      int minutes = 0;
      int seconds = 0;
      int hours = 0;
      if (parts.length == 3) {
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        seconds = double.parse(parts[2]).toInt();
      } else {
        minutes = int.parse(parts[0]);
        seconds = double.parse(parts[1]).toInt();
      }
      return ((hours * 3600) + (minutes * 60) + seconds) * 1000;
    } catch (_) {
      return null;
    }
  }

  static String _formatTimestamp(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// The full caption payload returned by /videos/{id}/captions.
class CaptionSet {
  CaptionSet({
    required this.videoId,
    required this.segments,
    this.language,
  });

  factory CaptionSet.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] ?? json['captions'] ?? [];
    return CaptionSet(
      videoId: json['video_id']?.toString() ?? '',
      segments: (segmentsJson as List)
          .map((e) => CaptionSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      language: json['language']?.toString(),
    );
  }

  final String videoId;
  final List<CaptionSegment> segments;
  final String? language;
}
