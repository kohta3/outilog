import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 広告ユニットID（テスト用と本番用を切り替え可能）
  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741' // テスト用バナー広告ID
      // ? 'ca-app-pub-6529629959594411/1594396384' // 本番用バナー広告ID
      // : 'ca-app-pub-6529629959594411/1576454204'; // iOS用本番バナー広告ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS用テストバナー広告ID

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // テスト用インタースティシャル広告ID
      // ? 'ca-app-pub-6529629959594411/7658646821' // 本番用インタースティシャル広告ID
      // : 'ca-app-pub-6529629959594411/1858120267'; // iOS用本番インタースティシャル広告ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS用テストインタースティシャル広告ID

  // リワード広告ID（一時的に無効化）
  // static String get _rewardedAdUnitId => Platform.isAndroid
  //     ? 'ca-app-pub-3940256099942544/5224354917' // テスト用リワード広告ID
  //     ? 'ca-app-pub-6529629959594411/3935024237' // 本番用リワード広告ID
  //     : 'ca-app-pub-3940256099942544/5224354917'; // iOS用テストID

  static String get _nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110' // テスト用ネイティブアドバンス広告ID
      // ? 'ca-app-pub-6529629959594411/1211253000' // 本番用ネイティブアドバンス広告ID
      : 'ca-app-pub-6529629959594411/8231956920'; // iOS用本番ネイティブアドバンス広告ID

  static String get _appOpenAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6529629959594411/7960494183' // 提供されたアプリ起動広告ID
      : 'ca-app-pub-6529629959594411/3063390724'; // iOS用本番アプリ起動広告ID

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  // RewardedAd? _rewardedAd; // リワード広告を一時的に無効化
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;

  bool _isInitialized = false;

  /// AdMobを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      print('AdMob initialized successfully');
    } catch (e) {
      print('Failed to initialize AdMob: $e');
    }
  }

  /// インタースティシャル広告を読み込み
  Future<void> loadInterstitialAd({
    required void Function(LoadAdError) onAdFailedToLoad,
    required void Function(InterstitialAd) onAdLoaded,
  }) async {
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
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
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
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
    await AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
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
  String get bannerAdUnitId => _bannerAdUnitId;

  /// インタースティシャル広告ユニットIDを取得
  String get interstitialAdUnitId => _interstitialAdUnitId;

  // リワード広告ユニットIDを取得（一時的に無効化）
  // String get rewardedAdUnitId => _rewardedAdUnitId;

  /// ネイティブアドバンス広告ユニットIDを取得
  String get nativeAdUnitId => _nativeAdUnitId;

  /// アプリ起動広告ユニットIDを取得
  String get appOpenAdUnitId => _appOpenAdUnitId;
}
