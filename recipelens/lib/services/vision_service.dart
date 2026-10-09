import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';

enum AiProvider { claude, gemini }

class VisionException implements Exception {
  VisionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends a photo to an AI vision model and returns ingredients plus recipe ideas.
/// Keys are injected at build time with --dart-define-from-file (never committed).
class VisionService {
  VisionService({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _claudeKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _claudeModel = String.fromEnvironment('CLAUDE_MODEL', defaultValue: 'claude-haiku-4-5-20251001');
  static const _geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  static List<AiProvider> get available => [
        if (_claudeKey.isNotEmpty) AiProvider.claude,
        if (_geminiKey.isNotEmpty) AiProvider.gemini,
      ];

  Future<ScanResult> analyze(Uint8List bytes, String mime, AiProvider provider,
      {List<String> diet = const []}) async {
    final type = const ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].contains(mime) ? mime : 'image/jpeg';
    final b64 = base64Encode(bytes);
    final prompt = _prompt(diet);
    try {
      final text = provider == AiProvider.claude
          ? await _claude(prompt, b64, type)
          : await _gemini(prompt, b64, type);
      return parse(text);
    } on VisionException {
      rethrow;
    } catch (_) {
      throw VisionException('Could not reach the AI service. Check your connection and try again.');
    }
  }

  static String _prompt(List<String> diet) => '''
Look at this photo of food ingredients. Identify the edible ingredients you can see, then suggest 3 recipes that mainly use them.
${diet.isEmpty ? '' : 'Dietary requirements: ${diet.join(', ')}. Every recipe must respect them.'}
Reply with JSON only, no markdown, in exactly this shape:
{"ingredients":["..."],"recipes":[{"title":"...","minutes":25,"difficulty":"Easy|Medium|Hard","uses":["ingredients from the photo"],"missing":["common extras needed"],"steps":["..."]}]}
If the photo shows no food, return {"ingredients":[],"recipes":[]}.''';

  /// Extracts the JSON object from a model reply, tolerating code fences or extra text.
  static ScanResult parse(String raw) {
    final start = raw.indexOf('{'), end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw VisionException('The AI reply was not in the expected format. Please try again.');
    }
    try {
      return ScanResult.fromJson(jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>);
    } catch (_) {
      throw VisionException('The AI reply could not be read. Please try again.');
    }
  }

  void _check(http.Response r) {
    if (r.statusCode == 200) return;
    throw VisionException('The AI request failed (${r.statusCode}). Check your API key and try again.');
  }

  Future<String> _claude(String prompt, String b64, String mime) async {
    final r = await _http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {'x-api-key': _claudeKey, 'anthropic-version': '2023-06-01', 'content-type': 'application/json'},
          body: jsonEncode({
            'model': _claudeModel,
            'max_tokens': 1800,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'image', 'source': {'type': 'base64', 'media_type': mime, 'data': b64}},
                  {'type': 'text', 'text': prompt},
                ],
              }
            ],
          }),
        )
        .timeout(const Duration(seconds: 60));
    _check(r);
    final parts = (jsonDecode(r.body)['content'] as List).where((c) => c['type'] == 'text');
    return parts.map((c) => c['text']).join();
  }

  Future<String> _gemini(String prompt, String b64, String mime) async {
    final r = await _http
        .post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent'),
          headers: {'x-goog-api-key': _geminiKey, 'content-type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {'inline_data': {'mime_type': mime, 'data': b64}},
                ],
              }
            ],
            'generationConfig': {'responseMimeType': 'application/json'},
          }),
        )
        .timeout(const Duration(seconds: 60));
    _check(r);
    return jsonDecode(r.body)['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
