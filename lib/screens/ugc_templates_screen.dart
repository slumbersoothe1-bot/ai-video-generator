import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';
import '../widgets/cards.dart';

/// UGC template definition.
class UgcTemplate {
  const UgcTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.aspectRatio,
    required this.subtitleStyle,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String aspectRatio;
  final String subtitleStyle;
  final int color;
}

const List<UgcTemplate> kUgcTemplates = [
  UgcTemplate(
    id: 'product_unboxing',
    name: 'Product Unboxing',
    description: 'Drop a product image and get an instant unboxing-style ad',
    icon: 'inventory_2',
    category: 'E-Commerce',
    aspectRatio: '9:16',
    subtitleStyle: 'Kinetic Pop',
    color: 0xFF00D9A3,
  ),
  UgcTemplate(
    id: 'before_after',
    name: 'Before & After',
    description: 'Show a transformation with a split-screen reveal',
    icon: 'compare',
    category: 'Beauty',
    aspectRatio: '9:16',
    subtitleStyle: 'Bold Lower Third',
    color: 0xFFFF6B35,
  ),
  UgcTemplate(
    id: 'testimonial',
    name: 'Customer Testimonial',
    description: 'UGC-style testimonial with kinetic subtitles',
    icon: 'format_quote',
    category: 'Social Proof',
    aspectRatio: '1:1',
    subtitleStyle: 'Chat Bubble',
    color: 0xFF5B8DEF,
  ),
  UgcTemplate(
    id: 'product_demo',
    name: 'Product Demo',
    description: 'Quick feature showcase with text overlays',
    icon: 'play_circle',
    category: 'E-Commerce',
    aspectRatio: '9:16',
    subtitleStyle: 'Feature Callout',
    color: 0xFFB47CE3,
  ),
  UgcTemplate(
    id: 'trend_remix',
    name: 'Trend Remix',
    description: 'Ride trending audio with your product',
    icon: 'trending_up',
    category: 'Trending',
    aspectRatio: '9:16',
    subtitleStyle: 'Beat Sync',
    color: 0xFF66BB6A,
  ),
  UgcTemplate(
    id: 'story_format',
    name: 'Story Format',
    description: 'Multi-slide story with swipe prompts',
    icon: 'auto_stories',
    category: 'Social',
    aspectRatio: '9:16',
    subtitleStyle: 'Story Caption',
    color: 0xFF00D4FF,
  ),
];

/// Screen for UGC & E-commerce Express Templates.
class UgcTemplatesScreen extends StatefulWidget {
  const UgcTemplatesScreen({super.key});

  @override
  State<UgcTemplatesScreen> createState() => _UgcTemplatesScreenState();
}

class _UgcTemplatesScreenState extends State<UgcTemplatesScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories =>
      ['All', ...kUgcTemplates.map((t) => t.category).toSet().toList()];

  List<UgcTemplate> get _filtered => _selectedCategory == 'All'
      ? kUgcTemplates
      : kUgcTemplates.where((t) => t.category == _selectedCategory).toList();

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
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _dropZone(),
                    const SizedBox(height: AppSpacing.lg),
                    _categoryFilter(),
                    const SizedBox(height: AppSpacing.md),
                    ..._filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final template = entry.value;
                      return _templateCard(template)
                          .animate()
                          .fadeIn(delay: (index * 60).ms)
                          .slideY(begin: 0.02);
                    }),
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
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
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
              'UGC Express Templates',
              style: AppText.heading.copyWith(fontSize: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02);
  }

  Widget _dropZone() {
    return GestureDetector(
      onTap: () {
        Haptics.select();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image picker would open here'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: SurfaceCard(
        glow: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Drop your product image',
                style: AppText.heading.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'ll match it with a trendy UGC layout instantly',
                style: AppText.bodySecondary.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _categoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              Haptics.select();
              setState(() => _selectedCategory = cat);
            },
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
                cat,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _templateCard(UgcTemplate template) {
    final color = Color(template.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_iconForName(template.icon), color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: AppText.heading.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: AppText.bodySecondary.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _tag(template.aspectRatio, color),
                      const SizedBox(width: 6),
                      _tag(template.subtitleStyle, color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                Haptics.heavy();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Using template: ${template.name}'),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.label.copyWith(fontSize: 10, color: color),
      ),
    );
  }

  IconData _iconForName(String name) {
    const map = {
      'inventory_2': Icons.inventory_2_outlined,
      'compare': Icons.compare,
      'format_quote': Icons.format_quote,
      'play_circle': Icons.play_circle_outline,
      'trending_up': Icons.trending_up,
      'auto_stories': Icons.auto_stories,
    };
    return map[name] ?? Icons.video_call;
  }
}
