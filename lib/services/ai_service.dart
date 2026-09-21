import '../services/api_client.dart';
import '../services/api_exception.dart';

/// Client for AI capabilities exposed by authenticated Edge Functions.
/// Provider credentials never ship in the Flutter bundle.
class AIService {
  AIService._();

  static final ApiClient _api = ApiClient.instance();

  static Future<AssistantReply> chat({
    required String message,
    String? selectedStyle,
    String? templateId,
    List<Map<String, String>> recentMessages = const [],
  }) async {
    final response = await _api.post(
      '/assistant',
      body: {
        'message': message,
        'selected_style': selectedStyle,
        'template_id': templateId,
        'recent_messages': recentMessages,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'The assistant returned an invalid response.');
    }
    return AssistantReply.fromJson(data);
  }
}

class AssistantReply {
  const AssistantReply({required this.message, this.suggestions = const [], this.templateId});

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      message: json['message']?.toString() ?? 'Try describing the product, audience, and mood.',
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
      templateId: json['template_id']?.toString(),
    );
  }

  final String message;
  final List<String> suggestions;
  final String? templateId;
}
