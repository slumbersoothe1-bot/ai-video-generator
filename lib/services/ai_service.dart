import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _hfApiKey = "YOUR_HUGGINGFACE_API_KEY";
  static const String _hfModelUrl = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0";

  static Future<String?> generateMedia(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_hfModelUrl),
        headers: {
          "Authorization": "Bearer $_hfApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inputs": prompt}),
      );

      if (response.statusCode == 200) {
        return "success";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> fetchStockMedia(String query) async {
    const String pexelsKey = "YOUR_PEXELS_API_KEY";
    try {
      final response = await http.get(
        Uri.parse("https://api.pexels.com/v1/search?query=$query&per_page=15"),
        headers: {"Authorization": pexelsKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['photos'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
