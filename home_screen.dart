import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../models/video_model.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'result_screen.dart';

/// Available generation styles shown in the selector.
const List<String> kVideoStyles = [
  'Cinematic',
  '3D Animation',
  'Anime',
  'Realistic',
  'Cyberpunk',
  'Watercolor',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _promptController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedStyle = kVideoStyles.first;
  bool _generating = false;
  VideoModel? _current;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? _defaultTitle(prompt)
        : _titleController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Please enter a prompt to describe your video.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _current = null;
    });
    try {
      final videoService = context.read<VideoService>();
      final initial = await videoService.generate(
        title: title,
        prompt: prompt,
        style: _selectedStyle,
      );
      setState(() => _current = initial);
      await videoService.pollUntilDone(
        initial.id,
        onUpdate: (v) {
          if (mounted) setState(() => _current = v);
        },
      );
      if (_current?.status == VideoStatus.completed && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(videoId: _current!.id),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Generation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _defaultTitle(String prompt) {
    if (prompt.length <= 40) return prompt;
    return '${prompt.substring(0, 40)}…';
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthService, String?>((a) => a.currentUser?.name);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(user)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _composer(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_error != null) _errorBanner(),
                    if (_generating || _current != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _progressCard(),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    _tips(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String? name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name?.split(' ').first ?? 'creator'}',
                  style: AppText.heading.copyWith(fontSize: 18),
                ),
                Text(
                  'What will you create today?',
                  style: AppText.bodySecondary.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Create a video',
            subtitle: 'Describe your scene and pick a visual style.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              prefixIcon: Icon(Icons.title_outlined, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _promptController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              alignLabelWithHint: true,
              hintText: 'A lone astronaut walking across a neon-lit alien desert at dusk…',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 120),
                child: Icon(Icons.edit_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Style', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          _styleSelector(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _generating ? 'Generating…' : 'Generate Video',
            icon: Icons.auto_awesome,
            isLoading: _generating,
            onPressed: _generating ? null : _generate,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03);
  }

  Widget _styleSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kVideoStyles.map((style) {
        final selected = style == _selectedStyle;
        return ChoiceChip(
          label: Text(style),
          selected: selected,
          onSelected: (_) => setState(() => _selectedStyle = style),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          labelStyle: AppText.label.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }).toList(),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(_error!, style: AppText.bodySecondary),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final video = _current;
    if (video == null) {
      return SurfaceCard(
        child: Row(
          children: [
            const LoadingState(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Submitting your request…',
                style: AppText.bodySecondary,
              ),
            ),
          ],
        ),
      );
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  video.title,
                  style: AppText.heading.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusPill(video.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: video.progress / 100,
              minHeight: 10,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                video.status.label,
                style: AppText.label.copyWith(fontSize: 12),
              ),
              Text(
                '${video.progress}%',
                style: AppText.label.copyWith(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (video.thumbnailUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ShimmerBox(height: 160),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _statusPill(VideoStatus status) {
    switch (status) {
      case VideoStatus.queued:
        return StatusPill(
          label: status.label,
          color: AppColors.warning,
          icon: Icons.queue,
        );
      case VideoStatus.processing:
        return StatusPill(
          label: status.label,
          color: AppColors.accent,
          icon: Icons.autorenew,
        );
      case VideoStatus.completed:
        return StatusPill(
          label: status.label,
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case VideoStatus.failed:
        return StatusPill(
          label: status.label,
          color: AppColors.error,
          icon: Icons.error_outline,
        );
      case VideoStatus.unknown:
        return StatusPill(label: status.label, color: AppColors.textMuted);
    }
  }

  Widget _tips() {
    final tips = [
      ('Be specific', 'Describe lighting, camera, mood, and motion.'),
      ('Keep it short', 'One focused scene works best for AI video.'),
      ('Pick a style', 'Styles strongly affect the final look.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tips for great results',
            style: AppText.heading.copyWith(fontSize: 16)),
        const SizedBox(height: AppSpacing.md),
        ...tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppText.bodySecondary,
                        children: [
                          TextSpan(
                            text: '${t.$1} — ',
                            style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: t.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
