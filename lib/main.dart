import 'package:colorist_ui/colorist_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_ai_agent/firebase_options.dart';
import 'package:weather_ai_agent/providers/gemini.dart';
import 'package:weather_ai_agent/services/gemini_chat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(geminiModelProvider);
    final conversationState = ref.watch(conversationStateProvider);

    return MaterialApp(
      title: 'Weather Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: model.when(
        data:
            (data) => MainScreen(
              conversationState: conversationState,
              sendMessage: (text) {
                ref.read(geminiChatServiceProvider).sendMessage(text);
              },
            ),
        loading: () => LoadingScreen(message: 'Initializing Gemini Model'),
        error: (err, st) => ErrorScreen(error: err),
      ),
    );
  }
}
