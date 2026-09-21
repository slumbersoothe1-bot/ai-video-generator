import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/ai_service.dart';
import '../services/api_exception.dart';
import '../widgets/feedback.dart';

class AIAssistantBotScreen extends StatefulWidget {
  const AIAssistantBotScreen({super.key, this.selectedStyle, this.templateId});
  final String? selectedStyle;
  final String? templateId;

  @override
  State<AIAssistantBotScreen> createState() => _AIAssistantBotScreenState();
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _AIAssistantBotScreenState extends State<AIAssistantBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text: 'Tell me what you want to promote and I will recommend a template, sharpen the prompt, and suggest a visual style.',
    ),
  ];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _error = null;
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final recent = _messages.take(8).map((message) => {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      }).toList();
      final reply = await AIService.chat(
        message: text,
        selectedStyle: widget.selectedStyle,
        templateId: widget.templateId,
        recentMessages: recent,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply.message, isUser: false));
        _sending = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; _sending = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'The assistant is unavailable right now. Try again in a moment.'; _sending = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Creative Assistant', style: AppText.heading),
                          Text('Templates, prompts, and direction', style: AppText.bodySecondary),
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: AppColors.accent),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_sending && index == _messages.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Align(alignment: Alignment.centerLeft, child: PremiumLoader(size: 34, label: 'Thinking…')),
                      );
                    }
                    final message = _messages[index];
                    return Align(
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: message.isUser ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: message.isUser ? AppColors.accent.withValues(alpha: 0.35) : AppColors.border),
                        ),
                        child: Text(message.text, style: AppText.body),
                      ),
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ErrorState(message: _error!),
                ),
              SizedBox(
                height: 42,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _quickPrompt('Recommend a template'),
                    _quickPrompt('Improve my product prompt'),
                    _quickPrompt('Make it more cinematic'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask for a prompt or template…',
                          prefixIcon: Icon(Icons.chat_bubble_outline, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      style: IconButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickPrompt(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _send(text),
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppText.label,
      ),
    );
  }
}
