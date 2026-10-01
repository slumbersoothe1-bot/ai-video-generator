import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import 'photo_video_maker_screen.dart';
import '../utils/haptics.dart';
import '../utils/viral_hook_engine.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';

/// Screen for generating viral hooks and multi-lingual marketing scripts.
class ViralHooksScreen extends StatefulWidget {
  const ViralHooksScreen({super.key});

  @override
  State<ViralHooksScreen> createState() => _ViralHooksScreenState();
}

class _ViralHooksScreenState extends State<ViralHooksScreen> {
  String _selectedNiche = kNiches.first;
  String _selectedLanguage = 'English';
  List<ViralHook> _hooks = [];
  String? _script;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    Haptics.select();
    setState(() {
      _loading = true;
      _hooks = [];
      _script = null;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _hooks = ViralHookEngine.generate(
            niche: _selectedNiche,
            language: _selectedLanguage,
          );
          _script = ViralHookEngine.generateScript(
            niche: _selectedNiche,
            language: _selectedLanguage,
          );
          _loading = false;
        });
        Haptics.success();
      }
    });
  }

  Future<void> _shareText(String text) async {
    try {
      await Share.share(text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing is unavailable in this browser. Use Copy instead.')));
    }
  }
  Future<void> _shareHook(ViralHook hook) => _shareText(hook.text);
  Future<void> _shareScript() async { if (_script != null) await _shareText(_script!); }
  Future<void> _copyHook(ViralHook hook) async {
    try {
      await Clipboard.setData(ClipboardData(text: hook.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hook copied to clipboard')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is unavailable. Select the text to copy it.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _selectors(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_loading) ...[
                      const PremiumLoader(size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          'Loading built-in templates...',
                          style: AppText.bodySecondary,
                        ),
                      ),
                    ] else ...[
                      _scriptSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                          'Scripts use fixed templates. Hooks stay in English. Scores are simple rules, not predictions.'),
                      _hooksSection(),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Hook & Script Templates',
              style: AppText.heading.copyWith(fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${kSupportedLanguages.length} languages',
              style:
                  AppText.label.copyWith(color: AppColors.accent, fontSize: 11),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02);
  }

  Widget _selectors() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Niche',
            style: AppText.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          _chipRow(kNiches, _selectedNiche, (v) {
            Haptics.select();
            setState(() => _selectedNiche = v);
          }),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Language',
            style: AppText.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          _languageRow(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Show Templates',
            icon: Icons.auto_awesome,
            onPressed: _generate,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02);
  }

  Widget _chipRow(
      List<String> items, String selected, void Function(String) onTap) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onTap(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Text(
              item,
              style: AppText.body.copyWith(
                fontSize: 13,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _languageRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kSupportedLanguages.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final lang = kSupportedLanguages[index];
          final isSelected = lang == _selectedLanguage;
          final flag = kLanguageFlags[lang] ?? '';
          return GestureDetector(
            onTap: () {
              Haptics.select();
              setState(() => _selectedLanguage = lang);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang,
                    style: AppText.body.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scriptSection() {
    if (_script == null) return const SizedBox.shrink();
    return SurfaceCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Marketing Script (template)',
                style: AppText.heading.copyWith(fontSize: 16),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _shareScript,
                child:
                    const Icon(Icons.share, color: AppColors.accent, size: 20),
              ),
            ],
          ),
          TextButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PhotoVideoMakerScreen(initialText: _script))),
              icon: const Icon(Icons.movie),
              label: const Text('Make video with this script')),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _script!,
              style: AppText.body.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Script language: $_selectedLanguage ${kLanguageFlags[_selectedLanguage] ?? ''}',
            style: AppText.label.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02);
  }

  Widget _hooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Hook Ideas',
              style: AppText.heading.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              '${_hooks.length} results',
              style: AppText.label.copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._hooks.asMap().entries.map((entry) {
          final index = entry.key;
          final hook = entry.value;
          return _hookCard(hook)
              .animate()
              .fadeIn(delay: (index * 80).ms)
              .slideY(begin: 0.03);
        }),
      ],
    );
  }

  Widget _hookCard(ViralHook hook) {
    final scoreColor = hook.score >= 85
        ? AppColors.success
        : hook.score >= 70
            ? AppColors.warning
            : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hook.text,
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
            TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PhotoVideoMakerScreen(initialText: hook.text))),
                child: const Text('Make video with this hook')),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: scoreColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Rule score ${hook.score}/99',
                        style: AppText.label.copyWith(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hook.reason,
                    style: AppText.label.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _copyHook(hook),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: AppText.label.copyWith(
                          color: AppColors.accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                GestureDetector(
                  onTap: () => _shareHook(hook),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: AppText.label.copyWith(
                          color: AppColors.accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
