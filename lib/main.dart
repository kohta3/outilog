import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/view/home_screen.dart';
import 'package:outi_log/view/auth/login_screen.dart';
import 'package:outi_log/services/notification_service.dart';
import 'package:outi_log/services/remote_notification_service.dart';
import 'package:outi_log/services/analytics_service.dart';
import 'package:outi_log/services/admob_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase初期化エラー: $e');
    // Firebase初期化に失敗した場合でもアプリを続行
  }

  // Crashlyticsを初期化
  FlutterError.onError = (errorDetails) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } catch (e) {
      print('Crashlyticsエラー記録失敗: $e');
    }
  };

  // プラットフォームエラーをCrashlyticsに送信
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (e) {
      print('Crashlyticsエラー記録失敗: $e');
    }
    return true;
  };

  // FCMバックグラウンドメッセージハンドラーを設定
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 画面を縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final container = ProviderContainer();
  final isFirstLogin =
      await container.read(loginRepoProvider).getIsFirstLogin();

  await initializeDateFormatting('ja_JP', null);

  // 通知サービスを初期化
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Analyticsサービスを初期化
  final analyticsService = AnalyticsService();
  await analyticsService.initialize();

  // AdMobサービスを初期化
  final admobService = AdMobService();
  await admobService.initialize();

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
      debugShowCheckedModeBanner: false,
      home: isFirstLogin ? const LoginScreen() : HomeScreen(),
    );
  }
}
