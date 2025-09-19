import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:outi_log/utils/memory_optimizer.dart';
import 'package:outi_log/utils/lazy_initializer.dart';
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

  // メモリ最適化の初期化（最初に実行）
  MemoryOptimizer.monitorMemoryUsage();

  // 初回起動時の最適化
  await _initializeAppSafely();

  runApp(
    ProviderScope(
      child: MyApp(
        isFirstLogin: isFirstLogin,
      ),
    ),
  );
}

/// アプリの安全な初期化（初回起動時対応）
Future<void> _initializeAppSafely() async {
  try {
    // サービスを遅延初期化として登録
    LazyInitializer.registerService('notification', () async {
      final service = NotificationService();
      await service.initialize();
      return service;
    });

    LazyInitializer.registerService('analytics', () async {
      final service = AnalyticsService();
      await service.initialize();
      return service;
    });

    LazyInitializer.registerService('admob', () async {
      final service = AdMobService();
      // 古いデバイスではAdMobの初期化を遅延
      if (kDebugMode) {
        print('AdMob initialization delayed for memory optimization');
      }
      return service;
    });

    // 初回起動時は最小限のサービスのみ初期化
    if (kDebugMode) {
      print('App initialized safely for first launch');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during app initialization: $e');
    }
    // 初期化に失敗してもアプリは続行
  }
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
