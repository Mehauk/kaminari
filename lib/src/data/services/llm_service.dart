import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LlmService {
  static const String modelName = 'gemini-2.5-flash'; // Fallback
  static const String preferredModel = 'gemini-3.1-flash-lite';

  GenerativeModel? _model;

  LlmService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: preferredModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0,
          topK: 1,
          topP: 1,
          responseMimeType: 'application/json',
        ),
      );
    }
  }

  /// Check if the service is ready (API key provided)
  bool isReady() {
    return _model != null;
  }

  /// Generate text (Streaming) using Gemini
  Stream<String> streamResponse(String prompt) async* {
    if (_model == null) {
      throw Exception(
        "Gemini API key is missing. Please provide GEMINI_API_KEY in your .env file.",
      );
    }

    try {
      final content = [Content.text(prompt)];
      final responseStream = _model!.generateContentStream(content);

      await for (final response in responseStream) {
        if (response.text != null) {
          yield response.text!;
        }
      }
    } catch (e) {
      // If the specific 3.1 model fails (e.g. not available yet), fallback to 1.5 flash
      if (e.toString().contains('model not found')) {
        final fallbackModel = GenerativeModel(
          model: modelName,
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        );
        final responseStream = fallbackModel.generateContentStream([
          Content.text(prompt),
        ]);
        await for (final response in responseStream) {
          if (response.text != null) {
            yield response.text!;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  static T extractJsonFromResponse<T>(
    String response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // Gemini often wraps JSON in markdown code blocks or adds conversational filler.
    // We attempt to extract the JSON block.
    try {
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = response.substring(startIndex, endIndex + 1);
        final jsonMap = Map<String, dynamic>.from(jsonDecode(jsonString));
        print("JSON: $jsonMap");
        return fromJson(jsonMap['properties'] ?? jsonMap);
      }

      // Fallback to previous logic if braces not found
      final cleanJson = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMap = Map<String, dynamic>.from(jsonDecode(cleanJson));
      return fromJson(jsonMap);
    } catch (e) {
      print("JSON Parsing Error: $e");
      print("Original Response: $response");
      rethrow;
    }
  }
}
