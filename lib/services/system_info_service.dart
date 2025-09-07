import 'package:cloud_firestore/cloud_firestore.dart';

class SystemInfo {
  final String version;
  final DateTime releaseDate;
  final String title;
  final String about;

  SystemInfo({
    required this.version,
    required this.releaseDate,
    required this.title,
    required this.about,
  });

  factory SystemInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SystemInfo(
      version: data['version'] ?? '1.0.?',
      releaseDate: (data['release_date'] as Timestamp).toDate(),
      title: data['title'] ?? 'バージョン1.0.1',
      about: data['about'] ?? '',
    );
  }
}

class SystemInfoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'system';

  /// システム情報を取得
  static Future<SystemInfo?> getSystemInfo() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('release_date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SystemInfo.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('システム情報の取得に失敗しました: $e');
      return null;
    }
  }

  /// バージョン情報を取得
  static Future<String> getVersion() async {
    final systemInfo = await getSystemInfo();
    return systemInfo?.version ?? '1.0.0';
  }

  /// リリース日を取得
  static Future<DateTime?> getReleaseDate() async {
    final systemInfo = await getSystemInfo();
    return systemInfo?.releaseDate;
  }

  /// リリース日を日本語形式で取得
  static Future<String> getReleaseDateFormatted() async {
    final releaseDate = await getReleaseDate();
    if (releaseDate == null) {
      return '2024年1月1日';
    }

    // 日本語形式でフォーマット
    final year = releaseDate.year;
    final month = releaseDate.month;
    final day = releaseDate.day;

    return '${year}年${month}月${day}日';
  }
}
