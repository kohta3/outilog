import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  static bool? _isIPad;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // デバイスタイプを判定するヘルパー関数
  static Future<bool> _checkIsIPad() async {
    if (_isIPad != null) return _isIPad!;

    if (Platform.isIOS) {
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        _isIPad = iosInfo.model.toLowerCase().contains('ipad');
        return _isIPad!;
      } catch (e) {
        print('Error detecting iPad: $e');
        _isIPad = false;
        return false;
      }
    }
    _isIPad = false;
    return false;
  }

  // 広告ユニットID（テスト用と本番用を切り替え可能）
  static Future<String> get _bannerAdUnitId async {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/9214589741'; // テスト用バナー広告ID
      return 'ca-app-pub-6529629959594411/1594396384'; // 本番用バナー広告ID
    } else if (Platform.isIOS) {
      final isIPad = await _checkIsIPad();
      if (isIPad) {
        return 'ca-app-pub-6529629959594411/1576454204'; // iPad用バナー広告ID（iPhoneと同じ）
      } else {
        return 'ca-app-pub-6529629959594411/1576454204'; // iPhone用バナー広告ID
      }
    }
    return 'ca-app-pub-3940256099942544/9214589741'; // デフォルト（テスト用）
  }

  static Future<String> get _interstitialAdUnitId async {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/1033173712'; // テスト用インタースティシャル広告ID
      return 'ca-app-pub-6529629959594411/7658646821'; // 本番用インタースティシャル広告ID
    } else if (Platform.isIOS) {
      final isIPad = await _checkIsIPad();
      if (isIPad) {
        return 'ca-app-pub-6529629959594411/1858120267'; // iPad用インタースティシャル広告ID（iPhoneと同じ）
      } else {
        return 'ca-app-pub-6529629959594411/1858120267'; // iPhone用インタースティシャル広告ID
      }
    }
    return 'ca-app-pub-3940256099942544/1033173712'; // デフォルト（テスト用）
  }

  // リワード広告ID（一時的に無効化）
  // static String get _rewardedAdUnitId => Platform.isAndroid
  //     ? 'ca-app-pub-3940256099942544/5224354917' // テスト用リワード広告ID
  //     ? 'ca-app-pub-6529629959594411/3935024237' // 本番用リワード広告ID
  //     : 'ca-app-pub-3940256099942544/5224354917'; // iOS用テストID

  static Future<String> get _nativeAdUnitId async {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/2247696110'; // テスト用ネイティブアドバンス広告ID
      return 'ca-app-pub-6529629959594411/1211253000'; // 本番用ネイティブアドバンス広告ID
    } else if (Platform.isIOS) {
      final isIPad = await _checkIsIPad();
      if (isIPad) {
        return 'ca-app-pub-6529629959594411/8231956920'; // iPad用ネイティブアドバンス広告ID（iPhoneと同じ）
      } else {
        return 'ca-app-pub-6529629959594411/8231956920'; // iPhone用ネイティブアドバンス広告ID
      }
    }
    return 'ca-app-pub-3940256099942544/2247696110'; // デフォルト（テスト用）
  }

  static Future<String> get _appOpenAdUnitId async {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6529629959594411/7960494183'; // 提供されたアプリ起動広告ID
    } else if (Platform.isIOS) {
      final isIPad = await _checkIsIPad();
      if (isIPad) {
        return 'ca-app-pub-6529629959594411/3063390724'; // iPad用アプリ起動広告ID（iPhoneと同じ）
      } else {
        return 'ca-app-pub-6529629959594411/3063390724'; // iPhone用アプリ起動広告ID
      }
    }
    return 'ca-app-pub-3940256099942544/3419835294'; // デフォルト（テスト用）
  }

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  // RewardedAd? _rewardedAd; // リワード広告を一時的に無効化
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;

  bool _isInitialized = false;
  int _bannerAdId = 0;
  int _nativeAdId = 0;
  int _interstitialAdId = 0;

  /// AdMobを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      print('AdMob initialized successfully');
    } catch (e) {
      print('Failed to initialize AdMob: $e');
      // 初期化に失敗してもアプリは続行
    }
  }

  /// 安全な広告読み込み（重複防止）
  Future<void> safeLoadAd<T>(
    String adType,
    Future<void> Function() loadFunction,
  ) async {
    try {
      await loadFunction();
    } catch (e) {
      if (e.toString().contains('already exists')) {
        print('$adType ad already exists, skipping load');
        return;
      }
      print('Error loading $adType ad: $e');
    }
  }

  /// インタースティシャル広告を読み込み
  Future<void> loadInterstitialAd({
    required void Function(LoadAdError) onAdFailedToLoad,
    required void Function(InterstitialAd) onAdLoaded,
  }) async {
    final adUnitId = await _interstitialAdUnitId;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  // リワード広告を読み込み（一時的に無効化）
  // Future<void> loadRewardedAd({
  //   required void Function(LoadAdError) onAdFailedToLoad,
  //   required void Function(RewardedAd) onAdLoaded,
  // }) async {
  //   // 既にリワード広告が読み込み中の場合は処理を停止
  //   if (_rewardedAd != null) {
  //     print('リワード広告は既に読み込み中です');
  //     return;
  //   }
  //
  //   await RewardedAd.load(
  //     adUnitId: _rewardedAdUnitId,
  //     request: const AdRequest(),
  //     rewardedAdLoadCallback: RewardedAdLoadCallback(
  //       onAdLoaded: (RewardedAd ad) {
  //         _rewardedAd = ad;
  //         onAdLoaded(ad);
  //       },
  //       onAdFailedToLoad: (LoadAdError error) {
  //         _rewardedAd = null; // エラー時はnullにリセット
  //         onAdFailedToLoad(error);
  //       },
  //     ),
  //   );
  // }

  /// ネイティブアドバンス広告を読み込み
  Future<void> loadNativeAd({
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
  }) async {
    final adUnitId = await _nativeAdUnitId;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 8.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (Ad ad) => print('Native ad opened'),
        onAdClosed: (Ad ad) => print('Native ad closed'),
      ),
    );

    _nativeAd?.load();
  }

  /// アプリ起動広告を読み込み
  Future<void> loadAppOpenAd({
    required void Function(LoadAdError) onAdFailedToLoad,
    required void Function(AppOpenAd) onAdLoaded,
  }) async {
    final adUnitId = await _appOpenAdUnitId;
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
          onAdFailedToLoad(error);
        },
      ),
    );
  }

  /// バナー広告を破棄
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// インタースティシャル広告を破棄
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  // リワード広告を破棄（一時的に無効化）
  // void disposeRewardedAd() {
  //   _rewardedAd?.dispose();
  //   _rewardedAd = null;
  // }

  /// ネイティブアドバンス広告を破棄
  void disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  /// アプリ起動広告を破棄
  void disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  /// 全ての広告を破棄
  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
    // disposeRewardedAd(); // リワード広告を一時的に無効化
    disposeNativeAd();
    disposeAppOpenAd();
  }

  /// 初期化状態を取得
  bool get isInitialized => _isInitialized;

  /// バナー広告ユニットIDを取得
  Future<String> get bannerAdUnitId => _bannerAdUnitId;

  /// インタースティシャル広告ユニットIDを取得
  Future<String> get interstitialAdUnitId => _interstitialAdUnitId;

  // リワード広告ユニットIDを取得（一時的に無効化）
  // String get rewardedAdUnitId => _rewardedAdUnitId;

  /// ネイティブアドバンス広告ユニットIDを取得
  Future<String> get nativeAdUnitId => _nativeAdUnitId;

  /// アプリ起動広告ユニットIDを取得
  Future<String> get appOpenAdUnitId => _appOpenAdUnitId;
}
