import 'dart:async';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:weather_ai_agent/providers/system_prompt.dart';
import 'package:weather_ai_agent/services/gemini_tools.dart';

part 'gemini.g.dart';

@Riverpod(keepAlive: true)
Future<GenerativeModel> geminiModel(Ref ref) async {
  final systemPrompt = await ref.watch(systemPromptProvider.future);
  final geminiTools = ref.watch(geminiToolsProvider);

  final model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.0-flash',
    systemInstruction: Content.system(systemPrompt),
    tools: geminiTools.tools,
  );
  return model;
}

@Riverpod(keepAlive: true)
Future<ChatSession> chatSession(Ref ref) async {
  final model = await ref.watch(geminiModelProvider.future);
  return model.startChat();
}
