import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/bug_report_model.dart';
import 'package:outi_log/provider/bug_report_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:outi_log/utils/image_optimizer.dart';

class BugReportScreen extends ConsumerStatefulWidget {
  const BugReportScreen({super.key});

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  BugReportPriority _selectedPriority = BugReportPriority.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'バグ報告',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showBugReportHistory(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー情報
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'バグ報告について',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'アプリで発生した不具合や改善提案をお聞かせください。\n'
                      '詳細な情報をいただくことで、より迅速な対応が可能になります。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // タイトル
              Text(
                'タイトル *',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例: ログイン時にエラーが発生する',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length < 5) {
                    return 'タイトルは5文字以上で入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 優先度
              Text(
                '優先度',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BugReportPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: BugReportPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        _getPriorityIcon(priority),
                        const SizedBox(width: 8),
                        Text(priority.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // 詳細説明
              Text(
                '詳細説明 *',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '不具合の詳細な状況を教えてください。\n'
                      '例：\n'
                      '• いつ発生したか\n'
                      '• どのような操作をしていたか\n'
                      '• 期待していた動作\n'
                      '• 実際に起こった動作',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '詳細説明を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '詳細説明は10文字以上で入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // スクリーンショット
              Text(
                'スクリーンショット（任意）',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageOptimizer.buildOptimizedFileImage(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _selectImage,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'スクリーンショットを追加',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'タップして画像を選択',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 32),

              // 送信ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBugReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('送信中...'),
                          ],
                        )
                      : const Text(
                          'バグ報告を送信',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 注意事項
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning,
                        color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'バグ報告を送信すると、開発チームが内容を確認し、必要に応じてご連絡いたします。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPriorityIcon(BugReportPriority priority) {
    switch (priority) {
      case BugReportPriority.low:
        return const Icon(Icons.keyboard_arrow_down, color: Colors.green);
      case BugReportPriority.medium:
        return const Icon(Icons.remove, color: Colors.orange);
      case BugReportPriority.high:
        return const Icon(Icons.keyboard_arrow_up, color: Colors.red);
      case BugReportPriority.critical:
        return const Icon(Icons.priority_high, color: Colors.purple);
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageOptimizer.screenshotOptions.maxWidth,
        maxHeight: ImageOptimizer.screenshotOptions.maxHeight,
        imageQuality: ImageOptimizer.screenshotOptions.imageQuality,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Toast.show(context, '画像の選択に失敗しました: $e');
    }
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      Toast.show(context, 'ログインが必要です');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bugReportId =
          await ref.read(bugReportProvider.notifier).createBugReport(
                userEmail: currentUser.email ?? '',
                userName: currentUser.displayName ?? 'Unknown User',
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                screenshotUrl: null, // TODO: 画像アップロード機能を実装
                priority: _selectedPriority,
              );

      if (bugReportId != null) {
        Toast.show(context, 'バグ報告を送信しました');

        // フォームをリセット
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedImage = null;
          _selectedPriority = BugReportPriority.medium;
        });
      } else {
        Toast.show(context, 'バグ報告の送信に失敗しました');
      }
    } catch (e) {
      Toast.show(context, 'エラーが発生しました: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showBugReportHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BugReportHistoryDialog(),
    );
  }
}

class BugReportHistoryDialog extends ConsumerWidget {
  const BugReportHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bugReportState = ref.watch(bugReportProvider);

    // バグ報告履歴を読み込み
    ref.listen(bugReportProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        // 読み込み完了
      }
    });

    // 初回読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bugReportProvider.notifier).loadUserBugReports();
    });

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'バグ報告履歴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: bugReportState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bugReportState.bugReports.isEmpty
                      ? const Center(
                          child: Text(
                            'バグ報告がありません',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: bugReportState.bugReports.length,
                          itemBuilder: (context, index) {
                            final bugReport = bugReportState.bugReports[index];
                            return _buildBugReportCard(bugReport);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugReportCard(BugReportModel bugReport) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bugReport.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _getStatusChip(bugReport.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bugReport.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _getPriorityChip(bugReport.priority),
                const Spacer(),
                Text(
                  '${bugReport.createdAt.year}/${bugReport.createdAt.month}/${bugReport.createdAt.day}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (bugReport.adminResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '管理者からの回答:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bugReport.adminResponse!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getStatusChip(BugReportStatus status) {
    Color color;
    switch (status) {
      case BugReportStatus.pending:
        color = Colors.orange;
        break;
      case BugReportStatus.inProgress:
        color = Colors.blue;
        break;
      case BugReportStatus.resolved:
        color = Colors.green;
        break;
      case BugReportStatus.closed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _getPriorityChip(BugReportPriority priority) {
    Color color;
    switch (priority) {
      case BugReportPriority.low:
        color = Colors.green;
        break;
      case BugReportPriority.medium:
        color = Colors.orange;
        break;
      case BugReportPriority.high:
        color = Colors.red;
        break;
      case BugReportPriority.critical:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
