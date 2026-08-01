import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../models/video_model.dart';
import '../services/api_exception.dart';
import '../services/video_service.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoModel? _video;
  CaptionSet? _captions;
  bool _loadingVideo = true;
  bool _loadingCaptions = false;
  String? _videoError;
  String? _captionError;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _loadingVideo = true;
      _videoError = null;
    });
    try {
      final video = await context.read<VideoService>().getVideo(widget.videoId);
      setState(() {
        _video = video;
        _loadingVideo = false;
      });
      if (video.status == VideoStatus.completed) {
        _loadCaptions();
      }
    } on ApiException catch (e) {
      setState(() {
        _videoError = e.message;
        _loadingVideo = false;
      });
    } catch (_) {
      setState(() {
        _videoError = 'Unable to load video.';
        _loadingVideo = false;
      });
    }
  }

  Future<void> _loadCaptions() async {
    setState(() {
      _loadingCaptions = true;
      _captionError = null;
    });
    try {
      final captions =
          await context.read<VideoService>().getCaptions(widget.videoId);
      setState(() {
        _captions = captions;
        _loadingCaptions = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _captionError = e.message;
        _loadingCaptions = false;
      });
    } catch (_) {
      setState(() {
        _captionError = 'Unable to load captions.';
        _loadingCaptions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _loadVideo,
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Result', style: AppText.heading.copyWith(fontSize: 20)),
          const Spacer(),
          if (_video?.videoUrl != null)
            GlassIconButton(
              icon: Icons.share,
              onPressed: () {
                Haptics.tap();
                Share.share('Check out my AI video: ${_video!.videoUrl}');
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _body() {
    if (_loadingVideo) {
      return const Center(child: PremiumLoader(label: 'Loading video…'));
    }
    if (_videoError != null && _video == null) {
      return Center(
        child: ErrorState(message: _videoError!, onRetry: _loadVideo),
      );
    }
    final video = _video!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _thumbnail(video),
        const SizedBox(height: AppSpacing.lg),
        _meta(video),
        const SizedBox(height: AppSpacing.lg),
        _palette(video),
        const SizedBox(height: AppSpacing.lg),
        _captionsSection(),
      ],
    );
  }

  Widget _thumbnail(VideoModel video) {
    final url = video.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ShimmerBox(height: 200),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image,
                      color: AppColors.textMuted, size: 36),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.movie_outlined,
                      color: Colors.white, size: 40),
                ),
              ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.98, 0.98), duration: 350.ms)
        .shimmer(
          duration: 3.seconds,
          color: Colors.white.withOpacity(0.04),
        );
  }

  Widget _meta(VideoModel video) {
    return SurfaceCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(video.title, style: AppText.heading.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              StatusPill(
                label: video.style,
                color: AppColors.accent,
                icon: Icons.brush,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: video.status.label,
                color: _statusColor(video.status),
                icon: _statusIcon(video.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Prompt', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(video.prompt, style: AppText.bodySecondary),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.02);
  }

  Widget _palette(VideoModel video) {
    final colors = video.colorPalette;
    if (colors.isEmpty) return const SizedBox.shrink();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Color palette',
            subtitle: 'Dominant colors extracted from your video.',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final hex = colors[index];
                final swatch = _parseColor(hex);
                return GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(hex)),
                    );
                  },
                  child: Tooltip(
                    message: hex,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (index * 80).ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 300.ms,
                    );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 200.ms);
  }

  Widget _captionsSection() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Captions',
            subtitle: 'Structured, timestamped transcript.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingCaptions)
            const Center(child: LoadingState(label: 'Loading captions…'))
          else if (_captionError != null)
            ErrorState(message: _captionError!, onRetry: _loadCaptions)
          else if (_captions == null || _captions!.segments.isEmpty)
            Text(
              'No captions available for this video yet.',
              style: AppText.bodySecondary,
            )
          else
            _captionList(_captions!),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 300.ms);
  }

  Widget _captionList(CaptionSet set) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: set.segments.length,
      separatorBuilder: (_, __) =>
          const Divider(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final seg = set.segments[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Text(
                seg.formattedStart,
                style: AppText.label.copyWith(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(seg.text, style: AppText.body),
            ),
          ],
        ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.03);
      },
    );
  }

  Color _statusColor(VideoStatus status) {
    switch (status) {
      case VideoStatus.queued:
        return AppColors.warning;
      case VideoStatus.processing:
        return AppColors.accent;
      case VideoStatus.completed:
        return AppColors.success;
      case VideoStatus.failed:
        return AppColors.error;
      case VideoStatus.unknown:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(VideoStatus status) {
    switch (status) {
      case VideoStatus.queued:
        return Icons.queue;
      case VideoStatus.processing:
        return Icons.autorenew;
      case VideoStatus.completed:
        return Icons.check_circle;
      case VideoStatus.failed:
        return Icons.error_outline;
      case VideoStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _parseColor(String hex) {
    var clean = hex.replaceAll('#', '');
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) clean = 'FF$clean';
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return AppColors.surfaceElevated;
    return Color(value);
  }
}
