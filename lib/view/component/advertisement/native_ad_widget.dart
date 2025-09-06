import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:outi_log/services/admob_service.dart';

class NativeAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;

  const NativeAdWidget({
    super.key,
    this.margin,
    this.padding,
    this.height,
    this.width,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    final admobService = AdMobService();

    admobService.loadNativeAd(
      onAdLoaded: (Ad ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
          _isAdFailed = false;
        });
        print('Native ad loaded successfully');
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        setState(() {
          _isAdLoaded = false;
          _isAdFailed = true;
        });
        print('Native ad failed to load: $error');
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdFailed) {
      // 広告の読み込みに失敗した場合は何も表示しない
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _nativeAd == null) {
      // 広告の読み込み中はプレースホルダーを表示
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'ネイティブ広告読み込み中...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      margin: widget.margin,
      padding: widget.padding,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

/// カスタムネイティブ広告ウィジェット
/// アプリのデザインに合わせてカスタマイズ可能
class CustomNativeAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CustomNativeAdWidget({
    super.key,
    this.margin,
    this.padding,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<CustomNativeAdWidget> createState() => _CustomNativeAdWidgetState();
}

class _CustomNativeAdWidgetState extends State<CustomNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    final admobService = AdMobService();

    admobService.loadNativeAd(
      onAdLoaded: (Ad ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
          _isAdFailed = false;
        });
        print('Custom native ad loaded successfully');
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        setState(() {
          _isAdLoaded = false;
          _isAdFailed = true;
        });
        print('Custom native ad failed to load: $error');
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdFailed) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _nativeAd == null) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[200],
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'カスタムネイティブ広告読み込み中...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}

/// リスト内で使用するネイティブ広告ウィジェット
class ListNativeAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ListNativeAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: padding,
      child: const NativeAdWidget(
        height: 120,
      ),
    );
  }
}

/// カード形式のネイティブ広告ウィジェット
class CardNativeAdWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const CardNativeAdWidget({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: const NativeAdWidget(
          height: 150,
        ),
      ),
    );
  }
}
