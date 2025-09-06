import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:outi_log/services/admob_service.dart';

class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isAdAvailable = false;
  bool _isShowingAd = false;

  /// アプリ起動広告を読み込み
  Future<void> loadAd() async {
    if (_isAdAvailable || _isShowingAd) return;

    try {
      final admobService = AdMobService();

      await admobService.loadAppOpenAd(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _isAdAvailable = true;
          print('App Open Ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdAvailable = false;
          print('App Open Ad failed to load: $error');
        },
      );
    } catch (e) {
      print('Error loading App Open Ad: $e');
      _isAdAvailable = false;
    }
  }

  /// アプリ起動広告を表示
  Future<void> showAdIfAvailable() async {
    if (!_isAdAvailable || _isShowingAd || _appOpenAd == null) {
      return;
    }

    _isShowingAd = true;

    try {
      _appOpenAd!.show();
    } catch (e) {
      print('Error showing App Open Ad: $e');
    } finally {
      _isAdAvailable = false;
      _appOpenAd = null;
      _isShowingAd = false;
    }
  }

  /// 広告が利用可能かどうか
  bool get isAdAvailable => _isAdAvailable;

  /// 広告を破棄
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdAvailable = false;
    _isShowingAd = false;
  }
}

/// アプリ起動広告を管理するウィジェット
class AppOpenAdWidget extends StatefulWidget {
  final Widget child;

  const AppOpenAdWidget({
    super.key,
    required this.child,
  });

  @override
  State<AppOpenAdWidget> createState() => _AppOpenAdWidgetState();
}

class _AppOpenAdWidgetState extends State<AppOpenAdWidget>
    with WidgetsBindingObserver {
  final AppOpenAdManager _adManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // アプリがフォアグラウンドに戻った時に広告を表示
        _showAdIfAvailable();
        break;
      case AppLifecycleState.paused:
        // アプリがバックグラウンドに移った時に広告を読み込み
        _loadAd();
        break;
      default:
        break;
    }
  }

  Future<void> _loadAd() async {
    await _adManager.loadAd();
  }

  Future<void> _showAdIfAvailable() async {
    await _adManager.showAdIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// アプリ起動時に広告を表示するウィジェット
class AppStartupAdWidget extends StatefulWidget {
  final Widget child;

  const AppStartupAdWidget({
    super.key,
    required this.child,
  });

  @override
  State<AppStartupAdWidget> createState() => _AppStartupAdWidgetState();
}

class _AppStartupAdWidgetState extends State<AppStartupAdWidget> {
  final AppOpenAdManager _adManager = AppOpenAdManager();
  bool _hasShownStartupAd = false;

  @override
  void initState() {
    super.initState();
    _loadAndShowStartupAd();
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _loadAndShowStartupAd() async {
    // 少し待ってから広告を読み込み（アプリの初期化を待つ）
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted || _hasShownStartupAd) return;

    try {
      await _adManager.loadAd();

      // 広告が読み込まれたら表示
      if (_adManager.isAdAvailable) {
        _hasShownStartupAd = true;
        await _adManager.showAdIfAvailable();
      }
    } catch (e) {
      print('Error in startup ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
