import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// メモリ使用量を最適化するためのユーティリティクラス
class MemoryOptimizer {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const int _maxCacheSize = 50; // 最大キャッシュ数

  /// データをキャッシュに保存
  static void cacheData(String key, dynamic data) {
    // キャッシュサイズ制限
    if (_cache.length >= _maxCacheSize) {
      _clearOldestCache();
    }
    
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// キャッシュからデータを取得
  static T? getCachedData<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null || 
        DateTime.now().difference(timestamp) > _cacheExpiration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  /// 古いキャッシュをクリア
  static void _clearOldestCache() {
    if (_cacheTimestamps.isEmpty) return;
    
    final oldestKey = _cacheTimestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    _cache.remove(oldestKey);
    _cacheTimestamps.remove(oldestKey);
  }

  /// 特定のキーのキャッシュをクリア
  static void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// 全てのキャッシュをクリア
  static void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// メモリ使用量を監視して警告を出す
  static void monitorMemoryUsage() {
    if (kDebugMode) {
      print('Memory Optimizer - Cache size: ${_cache.length}');
      print('Memory Optimizer - Cache keys: ${_cache.keys.toList()}');
    }
  }
}

/// 遅延読み込み用のデータローダー
class LazyDataLoader<T> {
  final Future<List<T>> Function(int offset, int limit) _loadFunction;
  final int _pageSize;
  final String _cacheKey;
  
  List<T> _data = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentOffset = 0;

  LazyDataLoader({
    required Future<List<T>> Function(int offset, int limit) loadFunction,
    required String cacheKey,
    int pageSize = 20,
  }) : _loadFunction = loadFunction,
       _cacheKey = cacheKey,
       _pageSize = pageSize;

  /// 初期データを読み込み
  Future<List<T>> loadInitialData() async {
    if (_isLoading) return _data;
    
    _isLoading = true;
    try {
      // キャッシュから取得を試行
      final cachedData = MemoryOptimizer.getCachedData<List<T>>(_cacheKey);
      if (cachedData != null) {
        _data = cachedData;
        _currentOffset = _data.length;
        return _data;
      }

      // データベースから読み込み
      final newData = await _loadFunction(0, _pageSize);
      _data = newData;
      _currentOffset = newData.length;
      _hasMoreData = newData.length == _pageSize;
      
      // キャッシュに保存
      MemoryOptimizer.cacheData(_cacheKey, _data);
      
      return _data;
    } finally {
      _isLoading = false;
    }
  }

  /// 次のページを読み込み
  Future<List<T>> loadNextPage() async {
    if (_isLoading || !_hasMoreData) return _data;
    
    _isLoading = true;
    try {
      final newData = await _loadFunction(_currentOffset, _pageSize);
      _data.addAll(newData);
      _currentOffset += newData.length;
      _hasMoreData = newData.length == _pageSize;
      
      // キャッシュを更新
      MemoryOptimizer.cacheData(_cacheKey, _data);
      
      return _data;
    } finally {
      _isLoading = false;
    }
  }

  /// データをリフレッシュ
  Future<List<T>> refresh() async {
    _data.clear();
    _currentOffset = 0;
    _hasMoreData = true;
    MemoryOptimizer.clearCache(_cacheKey);
    return await loadInitialData();
  }

  /// 現在のデータを取得
  List<T> get currentData => List.unmodifiable(_data);
  
  /// 読み込み中かどうか
  bool get isLoading => _isLoading;
  
  /// さらにデータがあるかどうか
  bool get hasMoreData => _hasMoreData;
}

/// メモリ効率的なリストビルダー
class MemoryEfficientListBuilder<T> {
  final LazyDataLoader<T> _loader;
  final Widget Function(BuildContext context, T item, int index) _itemBuilder;
  final Widget Function(BuildContext context)? _loadingWidget;
  final Widget Function(BuildContext context)? _emptyWidget;
  final Widget Function(BuildContext context)? _errorWidget;

  MemoryEfficientListBuilder({
    required LazyDataLoader<T> loader,
    required Widget Function(BuildContext context, T item, int index) itemBuilder,
    Widget Function(BuildContext context)? loadingWidget,
    Widget Function(BuildContext context)? emptyWidget,
    Widget Function(BuildContext context)? errorWidget,
  }) : _loader = loader,
       _itemBuilder = itemBuilder,
       _loadingWidget = loadingWidget,
       _emptyWidget = emptyWidget,
       _errorWidget = errorWidget;

  /// ListViewを構築
  Widget buildListView(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _loader.loadInitialData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingWidget?.call(context) ?? 
            const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _errorWidget?.call(context) ?? 
            Center(child: Text('エラー: ${snapshot.error}'));
        }
        
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return _emptyWidget?.call(context) ?? 
            const Center(child: Text('データがありません'));
        }
        
        return ListView.builder(
          itemCount: data.length + (_loader.hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= data.length) {
              // 次のページを読み込み
              _loader.loadNextPage().then((_) {
                // 必要に応じてUIを更新
              });
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            return _itemBuilder(context, data[index], index);
          },
        );
      },
    );
  }
}
