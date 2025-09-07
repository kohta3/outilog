import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/bug_report_model.dart';
import 'package:outi_log/repository/bug_report_repo.dart';
import 'package:outi_log/provider/auth_provider.dart';

final bugReportProvider =
    StateNotifierProvider<BugReportNotifier, BugReportState>((ref) {
  final repo = ref.watch(bugReportRepoProvider);
  final currentUser = ref.watch(currentUserProvider);
  return BugReportNotifier(repo, currentUser?.uid);
});

class BugReportState {
  final List<BugReportModel> bugReports;
  final bool isLoading;
  final String? error;

  BugReportState({
    this.bugReports = const [],
    this.isLoading = false,
    this.error,
  });

  BugReportState copyWith({
    List<BugReportModel>? bugReports,
    bool? isLoading,
    String? error,
  }) {
    return BugReportState(
      bugReports: bugReports ?? this.bugReports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BugReportNotifier extends StateNotifier<BugReportState> {
  final BugReportRepo _repo;
  final String? _userId;

  BugReportNotifier(this._repo, this._userId) : super(BugReportState());

  /// バグ報告を作成
  Future<String?> createBugReport({
    required String userEmail,
    required String userName,
    required String title,
    required String description,
    String? screenshotUrl,
    BugReportPriority priority = BugReportPriority.medium,
  }) async {
    if (_userId == null) {
      state = state.copyWith(error: 'ユーザーがログインしていません');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final bugReportId = await _repo.createBugReport(
        userId: _userId,
        userEmail: userEmail,
        userName: userName,
        title: title,
        description: description,
        screenshotUrl: screenshotUrl,
        priority: priority,
      );

      // バグ報告一覧を更新
      await loadUserBugReports();

      state = state.copyWith(isLoading: false);
      return bugReportId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'バグ報告の作成に失敗しました: $e',
      );
      return null;
    }
  }

  /// ユーザーのバグ報告一覧を読み込み
  Future<void> loadUserBugReports() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final bugReports = await _repo.getUserBugReports(_userId);
      state = state.copyWith(
        bugReports: bugReports,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'バグ報告一覧の取得に失敗しました: $e',
      );
    }
  }

  /// 特定のバグ報告を取得
  Future<BugReportModel?> getBugReport(String bugReportId) async {
    try {
      return await _repo.getBugReport(bugReportId);
    } catch (e) {
      state = state.copyWith(error: 'バグ報告の取得に失敗しました: $e');
      return null;
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
      final success = await _repo.updateBugReport(
        bugReportId: bugReportId,
        status: status,
        priority: priority,
        adminResponse: adminResponse,
      );

      if (success) {
        // バグ報告一覧を更新
        await loadUserBugReports();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'バグ報告の更新に失敗しました: $e');
      return false;
    }
  }

  /// バグ報告を削除
  Future<bool> deleteBugReport(String bugReportId) async {
    try {
      final success = await _repo.deleteBugReport(bugReportId);

      if (success) {
        // バグ報告一覧を更新
        await loadUserBugReports();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'バグ報告の削除に失敗しました: $e');
      return false;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 状態をリセット
  void reset() {
    state = BugReportState();
  }
}
