import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:outi_log/services/admob_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.margin,
    this.padding,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // 各BannerAdWidgetが独立したBannerAdインスタンスを作成
    _bannerAd = BannerAd(
      adUnitId: AdMobService().bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdFailed = false;
            });
            print('Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdFailed = true;
            });
            print('Banner ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('Banner ad opened'),
        onAdClosed: (Ad ad) => print('Banner ad closed'),
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdFailed) {
      // 広告の読み込みに失敗した場合は何も表示しない
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded) {
      // 広告の読み込み中はプレースホルダーを表示
      return Container(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '広告読み込み中...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      margin: widget.margin,
      padding: widget.padding,
      child: ClipRect(
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// 画面下部に固定表示するバナー広告ウィジェット
class BottomBannerAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const BottomBannerAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false, // 上部のSafeAreaは無効化
        child: SizedBox(
          height: 50, // バナー広告の標準高さ
          child: BannerAdWidget(
            adSize: AdSize.banner,
            margin: margin ??
                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            padding: padding,
          ),
        ),
      ),
    );
  }
}

/// 画面上部に表示するバナー広告ウィジェット
class TopBannerAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const TopBannerAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: BannerAdWidget(
          adSize: AdSize.banner,
          margin: margin ?? const EdgeInsets.all(8),
          padding: padding,
        ),
      ),
    );
  }
}

/// 大きなバナー広告ウィジェット（Large Banner）
class LargeBannerAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const LargeBannerAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BannerAdWidget(
      adSize: AdSize.largeBanner,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding,
    );
  }
}

/// 中サイズのバナー広告ウィジェット（Medium Rectangle）
class MediumRectangleAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const MediumRectangleAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BannerAdWidget(
      adSize: AdSize.mediumRectangle,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding,
    );
  }
}
