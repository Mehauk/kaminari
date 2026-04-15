import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

class LlmService {
  // Placeholder URL for the Gemma model. User must provide a real one.
  static const String modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q8_ekv4096.task';
  static const ModelType modelType = ModelType.gemmaIt;
  static const ModelFileType fileType = ModelFileType.task;
  static const int maxTokens = 4096;

  /// 1. Check if model is already on device
  Future<bool> isDownloaded() async {
    return await FlutterGemma.isModelInstalled(modelUrl.split('/').last);
  }

  /// 2. Download the model using FlutterGemma's installer
  InferenceInstallationBuilder download() {
    return FlutterGemma.installModel(modelType: modelType).fromNetwork(
      modelUrl,
      token: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
    );
  }

  /// 4. Generate text (Streaming)
  Stream<String> streamResponse(String prompt) async* {
    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: .gpu,
    );
    final session = await model.createChat();

    // Add user message to session
    await session.addQueryChunk(Message.text(text: prompt, isUser: true));

    // Generate and yield response tokens
    await for (final response in session.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }

    session.close();
    model.close();
  }
}
