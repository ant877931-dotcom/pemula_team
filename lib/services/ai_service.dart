import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey = "sk-qz1-zMuj5405dY1rB2ao-w";
  final String baseUrl = "https://litellm.koboi2026.biz.id/v1/chat/completions";

  Future<String> getAIResponse(String prompt, String systemContext) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model":
              "gpt-3.5-turbo", 
          "messages": [
            {"role": "system", "content": systemContext},
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Gagal terhubung ke AI: $e";
    }
  }
}
