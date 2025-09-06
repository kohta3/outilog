import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:outi_log/services/analytics_service.dart';

class SpaceInviteScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;

  const SpaceInviteScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  ConsumerState<SpaceInviteScreen> createState() => _SpaceInviteScreenState();
}

class _SpaceInviteScreenState extends ConsumerState<SpaceInviteScreen> {
  String? _inviteCode;
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 既存の招待コードを取得
      final inviteCode = await ref
          .read(firestoreSpacesProvider.notifier)
          .createInviteCode(widget.spaceId);

      setState(() {
        _inviteCode = inviteCode;
      });

      // 招待コード生成時にAnalyticsイベントを記録
      AnalyticsService().logSpaceInvite();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待コードの取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateNewInviteCode() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final newInviteCode = await ref
          .read(firestoreSpacesProvider.notifier)
          .createInviteCode(widget.spaceId);

      setState(() {
        _inviteCode = newInviteCode;
      });

      if (mounted) {
        Toast.show(context, '新しい招待コードを生成しました');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待コードの生成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _copyInviteCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      Toast.show(context, '招待コードをコピーしました');
    }
  }

  Future<void> _shareToLine() async {
    if (_inviteCode == null) return;

    final message = _buildShareMessage();
    final encodedMessage = Uri.encodeComponent(message);
    const lineShareUrl = 'https://line.me/R/msg/text/?';
    final lineUrl = '$lineShareUrl$encodedMessage';

    try {
      if (await canLaunchUrl(Uri.parse(lineUrl))) {
        await launchUrl(Uri.parse(lineUrl));
      } else {
        Toast.show(context, 'LINEを開けませんでした');
      }
    } catch (e) {
      Toast.show(context, 'LINEを開けませんでした');
    }
  }

  String _buildShareMessage() {
    return 'おうちログに招待されました！\n\n'
        'スペース: ${widget.spaceName}\n'
        '招待コード: $_inviteCode\n\n'
        'このコードを使ってスペースに参加してください。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('招待コード'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // スペース情報
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: themeColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.spaceName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'このスペースに招待するためのコードです',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 招待コード表示
                  if (_inviteCode != null) ...[
                    const Text(
                      '招待コード',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _inviteCode!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _copyInviteCode,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('コピー'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _shareToLine,
                                  icon: const Icon(Icons.share),
                                  label: const Text('LINEで共有'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: themeColor),
                                    foregroundColor: themeColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 新しい招待コード生成ボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isGenerating ? null : _generateNewInviteCode,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(_isGenerating ? '生成中...' : '新しいコードを生成'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    // 招待コードが取得できない場合
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '招待コードの取得に失敗しました',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '再度お試しください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadInviteCode,
                            icon: const Icon(Icons.refresh),
                            label: const Text('再試行'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 使用方法の説明
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '使用方法',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. 招待コードをコピーまたは共有\n'
                          '2. 招待したい人にコードを送信\n'
                          '3. 相手がアプリで「スペースに参加」からコードを入力\n'
                          '4. 自動的にスペースに参加されます',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
