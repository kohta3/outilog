import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/view/home_screen.dart';
import 'package:outi_log/view/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 画面を縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final container = ProviderContainer();
  final isFirstLogin =
      await container.read(loginRepoProvider).getIsFirstLogin();

  await initializeDateFormatting('ja_JP', null);
  runApp(
    ProviderScope(
      child: MyApp(
        isFirstLogin: isFirstLogin,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isFirstLogin});

  final bool isFirstLogin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おうちログ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      home: isFirstLogin ? const LoginScreen() : HomeScreen(),
    );
  }
}
