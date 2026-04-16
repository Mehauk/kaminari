import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LlmService {
  static const String modelName = 'gemini-2.5-flash'; // Fallback
  static const String preferredModel = 'gemini-3.1-flash-lite';

  GenerativeModel? _model;

  LlmService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(model: preferredModel, apiKey: apiKey);
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
}
