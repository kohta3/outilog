import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/bug_report_model.dart';
import 'package:outi_log/infrastructure/bug_report_firestore_infrastructure.dart';
import 'dart:io';

final bugReportRepoProvider = Provider<BugReportRepo>((ref) {
  return BugReportRepo();
});

class BugReportRepo {
  final BugReportFirestoreInfrastructure _infrastructure =
      BugReportFirestoreInfrastructure();

  /// バグ報告を作成
  Future<String> createBugReport({
    required String userId,
    required String userEmail,
    required String userName,
    required String title,
    required String description,
    String? screenshotUrl,
    BugReportPriority priority = BugReportPriority.medium,
  }) async {
    try {
      // デバイス情報を取得
      final deviceInfo = await _getDeviceInfo();

      return await _infrastructure.createBugReport(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        title: title,
        description: description,
        deviceInfo: deviceInfo,
        appVersion: '1.0.0', // TODO: パッケージ情報から取得
        osVersion: await _getOsVersion(),
        screenshotUrl: screenshotUrl,
        priority: priority,
      );
    } catch (e) {
      debugPrint('DEBUG: Error creating bug report: $e');
      throw Exception('バグ報告の作成に失敗しました: $e');
    }
  }

  /// ユーザーのバグ報告一覧を取得
  Future<List<BugReportModel>> getUserBugReports(String userId) async {
    try {
      return await _infrastructure.getUserBugReports(userId);
    } catch (e) {
      debugPrint('DEBUG: Error getting user bug reports: $e');
      throw Exception('バグ報告一覧の取得に失敗しました: $e');
    }
  }

  /// 特定のバグ報告を取得
  Future<BugReportModel?> getBugReport(String bugReportId) async {
    try {
      return await _infrastructure.getBugReport(bugReportId);
    } catch (e) {
      debugPrint('DEBUG: Error getting bug report: $e');
      throw Exception('バグ報告の取得に失敗しました: $e');
    }
  }

  /// バグ報告を更新
  Future<bool> updateBugReport({
    required String bugReportId,
    BugReportStatus? status,
    BugReportPriority? priority,
    String? adminResponse,
  }) async {
    try {
      return await _infrastructure.updateBugReport(
        bugReportId: bugReportId,
        status: status,
        priority: priority,
        adminResponse: adminResponse,
      );
    } catch (e) {
      debugPrint('DEBUG: Error updating bug report: $e');
      throw Exception('バグ報告の更新に失敗しました: $e');
    }
  }

  /// バグ報告を削除
  Future<bool> deleteBugReport(String bugReportId) async {
    try {
      return await _infrastructure.deleteBugReport(bugReportId);
    } catch (e) {
      debugPrint('DEBUG: Error deleting bug report: $e');
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
      return await _infrastructure.getAllBugReports(
        status: status,
        priority: priority,
        limit: limit,
      );
    } catch (e) {
      debugPrint('DEBUG: Error getting all bug reports: $e');
      throw Exception('バグ報告一覧の取得に失敗しました: $e');
    }
  }

  /// バグ報告の統計情報を取得（管理者用）
  Future<Map<String, int>> getBugReportStats() async {
    try {
      return await _infrastructure.getBugReportStats();
    } catch (e) {
      debugPrint('DEBUG: Error getting bug report stats: $e');
      throw Exception('バグ報告統計の取得に失敗しました: $e');
    }
  }

  /// デバイス情報を取得
  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Unknown Platform';
      }
    } catch (e) {
      debugPrint('DEBUG: Error getting device info: $e');
      return 'Device info unavailable';
    }
  }

  /// OSバージョンを取得
  Future<String> _getOsVersion() async {
    try {
      if (Platform.isAndroid) {
        return 'Android';
      } else if (Platform.isIOS) {
        return 'iOS';
      } else {
        return 'Unknown OS';
      }
    } catch (e) {
      debugPrint('DEBUG: Error getting OS version: $e');
      return 'OS version unavailable';
    }
  }
}
