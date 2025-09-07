import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/models/bug_report_model.dart';

class BugReportFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // コレクション名
  static const String _bugReportsCollection = 'bug_reports';

  /// バグ報告を作成
  Future<String> createBugReport({
    required String userId,
    required String userEmail,
    required String userName,
    required String title,
    required String description,
    required String deviceInfo,
    required String appVersion,
    required String osVersion,
    String? screenshotUrl,
    BugReportPriority priority = BugReportPriority.medium,
  }) async {
    try {
      final bugReportRef = _firestore.collection(_bugReportsCollection).doc();

      final bugReportData = {
        'id': bugReportRef.id,
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName,
        'title': title,
        'description': description,
        'device_info': deviceInfo,
        'app_version': appVersion,
        'os_version': osVersion,
        'screenshot_url': screenshotUrl,
        'status': BugReportStatus.pending.value,
        'priority': priority.value,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'admin_response': null,
      };

      await bugReportRef.set(bugReportData);
      return bugReportRef.id;
    } catch (e) {
      throw Exception('バグ報告の作成に失敗しました: $e');
    }
  }

  /// ユーザーのバグ報告一覧を取得
  Future<List<BugReportModel>> getUserBugReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bugReportsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BugReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('バグ報告一覧の取得に失敗しました: $e');
    }
  }

  /// 特定のバグ報告を取得
  Future<BugReportModel?> getBugReport(String bugReportId) async {
    try {
      final doc = await _firestore
          .collection(_bugReportsCollection)
          .doc(bugReportId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return BugReportModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('バグ報告の取得に失敗しました: $e');
    }
  }

  /// バグ報告を更新（管理者用）
  Future<bool> updateBugReport({
    required String bugReportId,
    BugReportStatus? status,
    BugReportPriority? priority,
    String? adminResponse,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (status != null) {
        updateData['status'] = status.value;
      }

      if (priority != null) {
        updateData['priority'] = priority.value;
      }

      if (adminResponse != null) {
        updateData['admin_response'] = adminResponse;
      }

      await _firestore
          .collection(_bugReportsCollection)
          .doc(bugReportId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('バグ報告の更新に失敗しました: $e');
    }
  }

  /// バグ報告を削除
  Future<bool> deleteBugReport(String bugReportId) async {
    try {
      await _firestore
          .collection(_bugReportsCollection)
          .doc(bugReportId)
          .delete();

      return true;
    } catch (e) {
      throw Exception('バグ報告の削除に失敗しました: $e');
    }
  }

  /// 全バグ報告を取得（管理者用）
  Future<List<BugReportModel>> getAllBugReports({
    BugReportStatus? status,
    BugReportPriority? priority,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_bugReportsCollection)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.value);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              BugReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('バグ報告一覧の取得に失敗しました: $e');
    }
  }

  /// バグ報告の統計情報を取得（管理者用）
  Future<Map<String, int>> getBugReportStats() async {
    try {
      final querySnapshot =
          await _firestore.collection(_bugReportsCollection).get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';

        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('バグ報告統計の取得に失敗しました: $e');
    }
  }
}
