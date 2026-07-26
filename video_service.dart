import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/video_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Service that creates video generation jobs, polls their status, and
/// fetches captions.
class VideoService extends ChangeNotifier {
  VideoService(this._api);

  final ApiClient _api;

  /// Submits a new video generation request.
  ///
  /// Returns the initial [VideoModel] (usually in `queued` status).
  Future<VideoModel> generate({
    required String title,
    required String prompt,
    required String style,
  }) async {
    final response = await _api.post(
      '/videos-generate',
      body: {
        'title': title,
        'prompt': prompt,
        'style': style,
      },
    );
    return VideoModel.fromJson(_asMap(response.data));
  }

  /// Fetches the current state of a single video job.
  Future<VideoModel> getVideo(String id) async {
    final response = await _api.get('/videos-generate?id=$id');
    return VideoModel.fromJson(_asMap(response.data));
  }

  /// Fetches the caption set for a completed video.
  Future<CaptionSet> getCaptions(String videoId) async {
    final response = await _api.get('/videos-captions?video_id=$videoId');
    return CaptionSet.fromJson(_asMap(response.data));
  }

  /// Polls the video status until it reaches a terminal state
  /// (completed/failed) or [maxAttempts] is exceeded.
  ///
  /// [onUpdate] is invoked on every poll with the latest snapshot, so the
  /// UI can reflect progress in real time.
  Future<VideoModel> pollUntilDone(
    String videoId, {
    required void Function(VideoModel) onUpdate,
    int maxAttempts = 120,
  }) async {
    VideoModel current = await getVideo(videoId);
    onUpdate(current);

    int attempts = 0;
    while (!current.status.isTerminal && attempts < maxAttempts) {
      await Future<void>.delayed(
        const Duration(milliseconds: AppConfig.statusPollIntervalMs),
      );
      attempts += 1;
      try {
        current = await getVideo(videoId);
        onUpdate(current);
      } on ApiException {
        // Transient network blip: keep polling, surface last known state.
        onUpdate(current);
      }
    }
    return current;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // fall through
      }
    }
    throw ApiException(message: 'Unexpected server response.');
  }
}
