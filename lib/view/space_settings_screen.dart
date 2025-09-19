import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
import 'package:outi_log/infrastructure/space_infrastructure.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:outi_log/utils/image_optimizer.dart';

class SpaceSettingsScreen extends ConsumerStatefulWidget {
  final SpaceModel space;

  const SpaceSettingsScreen({
    super.key,
    required this.space,
  });

  @override
  ConsumerState<SpaceSettingsScreen> createState() =>
      _SpaceSettingsScreenState();
}

class _SpaceSettingsScreenState extends ConsumerState<SpaceSettingsScreen> {
  bool _isEditingSpaceName = false;
  late TextEditingController _spaceNameController;
  String? _inviteCode;
  bool _isLoadingInviteCode = false;
  File? _selectedHeaderImage;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoadingParticipants = false;
  bool _isUploadingHeaderImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _spaceNameController = TextEditingController(text: widget.space.spaceName);
    _loadInviteCode();
    _loadParticipants();
  }

  @override
  void dispose() {
    _spaceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('${widget.space.spaceName} の設定'),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: ListView(
        children: [
          // スペース情報セクション
          const _SettingsSection(title: 'スペース情報'),

          _buildSpaceNameTile(),
          _buildHeaderImageTile(),

          const Divider(),

          // 参加者セクション
          const _SettingsSection(title: '参加者'),
          _buildParticipantsSection(),

          const Divider(),

          // 招待・共有セクション
          const _SettingsSection(title: '招待・共有'),

          _buildInviteCodeSection(),

          const Divider(),

          // 危険な操作セクション
          const _SettingsSection(title: '削除'),

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('スペースを削除'),
            subtitle: const Text('このスペースを完全に削除'),
            onTap: () {
              _showDeleteSpaceDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// スペース名のタイルを構築
  Widget _buildSpaceNameTile() {
    return ListTile(
      leading: const Icon(Icons.home),
      title: _isEditingSpaceName
          ? TextField(
              controller: _spaceNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _saveSpaceName();
              },
            )
          : Text(
              widget.space.spaceName,
              style: const TextStyle(fontSize: 16),
            ),
      subtitle: const Text('スペース名'),
      trailing: _isEditingSpaceName
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveSpaceName,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelSpaceNameEdit,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startSpaceNameEdit,
            ),
    );
  }

  /// スペース名の編集を開始
  void _startSpaceNameEdit() {
    setState(() {
      _isEditingSpaceName = true;
    });
  }

  /// スペース名の編集をキャンセル
  void _cancelSpaceNameEdit() {
    setState(() {
      _isEditingSpaceName = false;
      _spaceNameController.text = widget.space.spaceName;
    });
  }

  /// スペース名を保存
  void _saveSpaceName() async {
    final newName = _spaceNameController.text.trim();
    if (newName.isEmpty) {
      Toast.show(context, 'スペース名を入力してください');
      return;
    }

    if (newName == widget.space.spaceName) {
      setState(() {
        _isEditingSpaceName = false;
      });
      return;
    }

    try {
      // スペース名を更新
      final success =
          await ref.read(firestoreSpacesProvider.notifier).updateSpaceName(
                spaceId: widget.space.id,
                newSpaceName: newName,
              );

      if (success) {
        setState(() {
          _isEditingSpaceName = false;
        });

        Toast.show(context, 'スペース名を変更しました');
      } else {
        Toast.show(context, 'スペース名の変更に失敗しました');
      }
    } catch (e) {
      Toast.show(context, 'スペース名の変更に失敗しました: $e');
    }
  }

  /// 招待コードを読み込み
  Future<void> _loadInviteCode() async {
    setState(() {
      _isLoadingInviteCode = true;
    });

    try {
      final inviteCode = await ref
          .read(firestoreSpacesProvider.notifier)
          .getOrCreateInviteCode(widget.space.id);

      setState(() {
        _inviteCode = inviteCode;
      });
    } catch (e) {
      print('Error loading invite code: $e');
      if (mounted) {
        Toast.show(context, '招待コードの取得に失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInviteCode = false;
        });
      }
    }
  }

  /// ヘッダー画像タイルを構築
  Widget _buildHeaderImageTile() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'ヘッダー画像',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 現在のヘッダー画像プレビュー
            if (widget.space.headerImageUrl != null ||
                _selectedHeaderImage != null)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedHeaderImage != null
                      ? ImageOptimizer.buildOptimizedFileImage(
                          _selectedHeaderImage!,
                          fit: BoxFit.cover,
                        )
                      : widget.space.headerImageUrl != null
                          ? ImageOptimizer.buildOptimizedNetworkImage(
                              widget.space.headerImageUrl!,
                              fit: BoxFit.cover,
                              maxBytes: 2 * 1024 * 1024, // 2MB制限
                              errorWidget: Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                          : null,
                ),
              ),

            const SizedBox(height: 12),

            // ボタン群
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploadingHeaderImage ? null : _selectHeaderImage,
                    icon: _isUploadingHeaderImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload),
                    label:
                        Text(_isUploadingHeaderImage ? 'アップロード中...' : '画像を選択'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (widget.space.headerImageUrl != null ||
                    _selectedHeaderImage != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _isUploadingHeaderImage ? null : _removeHeaderImage,
                    icon: const Icon(Icons.delete),
                    label: const Text('削除'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ヘッダー画像を選択
  Future<void> _selectHeaderImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageOptimizer.headerImageOptions.maxWidth,
        maxHeight: ImageOptimizer.headerImageOptions.maxHeight,
        imageQuality: ImageOptimizer.headerImageOptions.imageQuality,
      );

      if (image != null) {
        setState(() {
          _selectedHeaderImage = File(image.path);
        });

        await _uploadHeaderImage();
      }
    } catch (e) {
      Toast.show(context, '画像の選択に失敗しました: $e');
    }
  }

  /// ヘッダー画像をアップロード
  Future<void> _uploadHeaderImage() async {
    if (_selectedHeaderImage == null) return;

    setState(() {
      _isUploadingHeaderImage = true;
    });

    try {
      final storageInfrastructure = StorageInfrastructure();
      final imageUrl = await storageInfrastructure.uploadSpaceHeaderImage(
        spaceId: widget.space.id,
        imageFile: XFile(_selectedHeaderImage!.path),
      );

      // FirestoreでスペースのheaderImageUrlを更新
      print('DEBUG: Uploading header image URL to Firestore: $imageUrl');
      final success = await ref
          .read(firestoreSpacesProvider.notifier)
          .updateSpaceHeaderImage(widget.space.id, imageUrl);

      if (success) {
        print('DEBUG: Header image URL saved successfully');
        Toast.show(context, 'ヘッダー画像をアップロードしました');
      } else {
        print('DEBUG: Failed to save header image URL');
        Toast.show(context, 'ヘッダー画像の保存に失敗しました');
      }
    } catch (e) {
      Toast.show(context, 'ヘッダー画像のアップロードに失敗しました: $e');
    } finally {
      setState(() {
        _isUploadingHeaderImage = false;
      });
    }
  }

  /// ヘッダー画像を削除
  Future<void> _removeHeaderImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘッダー画像を削除'),
        content: const Text('ヘッダー画像を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _selectedHeaderImage = null;
              });

              // FirestoreでスペースのheaderImageUrlをnullに更新
              final success = await ref
                  .read(firestoreSpacesProvider.notifier)
                  .updateSpaceHeaderImage(widget.space.id, null);

              if (success) {
                Toast.show(context, 'ヘッダー画像を削除しました');
              } else {
                Toast.show(context, 'ヘッダー画像の削除に失敗しました');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 招待コードセクションを構築
  Widget _buildInviteCodeSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  '招待コード',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isLoadingInviteCode
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inviteCode ?? 'コードを取得中...',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (_inviteCode != null)
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _inviteCode!));
                              Toast.show(context, '招待コードをコピーしました');
                            },
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _inviteCode != null
                    ? () {
                        _shareViaLine(context);
                      }
                    : null,
                icon: const Icon(Icons.share),
                label: const Text('LINEで共有'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 参加者セクションを構築
  Widget _buildParticipantsSection() {
    if (_isLoadingParticipants) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: _participants.isEmpty
            ? const Center(
                child: Text(
                  '参加者がいません',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            : Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                alignment: WrapAlignment.start,
                children: _participants.map((participant) {
                  return _buildParticipantChip(participant);
                }).toList(),
              ),
      ),
    );
  }

  /// 参加者データを読み込み
  Future<void> _loadParticipants() async {
    if (_isLoadingParticipants) return;

    setState(() {
      _isLoadingParticipants = true;
    });

    try {
      final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
      if (currentSpace == null) {
        print('DEBUG: No current space found');
        setState(() {
          _participants = [];
          _isLoadingParticipants = false;
        });
        return;
      }

      // スペース参加者を取得
      final spaceInfrastructure = SpaceInfrastructure();
      final spaceDetails =
          await spaceInfrastructure.getSpaceDetails(currentSpace.id);
      final participants = spaceDetails?['participants'] ?? [];

      print(
          'DEBUG: Loaded ${participants.length} participants for space ${currentSpace.id}');
      for (final participant in participants) {
        print(
            'DEBUG: - ${participant['user_name']} (${participant['user_id']}) - ${participant['role']}');
      }

      setState(() {
        _participants = participants;
        _isLoadingParticipants = false;
      });
    } catch (e) {
      print('Warning: Could not load participants: $e');
      setState(() {
        _participants = [];
        _isLoadingParticipants = false;
      });
    }
  }

  /// 参加者チップを構築
  Widget _buildParticipantChip(Map<String, dynamic> participant) {
    final userName = participant['user_name'] as String? ??
        participant['user_email'] as String? ??
        '不明';
    final role = participant['role'] as String? ?? 'member';
    final profileImageUrl = participant['profile_image_url'] as String?;
    final userId = participant['user_id'] as String?;
    final isOwner = role == 'owner';

    // 現在のユーザーがオーナーかどうかを判定
    final currentUser = ref.read(currentUserProvider);
    final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
    bool isCurrentUserOwner = false;

    if (currentUser != null && currentSpace != null) {
      // 現在のユーザーがオーナーかどうかを判定（ownerIdと比較）
      isCurrentUserOwner = currentSpace.ownerId == currentUser.uid;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // プロフィール画像アイコン
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: role == 'owner' ? Colors.orange : themeColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: role == 'owner' ? Colors.orange : themeColor,
                backgroundImage:
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            // 役割アイコン（オーナーの場合のみ）
            if (isOwner)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            // 削除ボタン（現在のユーザーがオーナーで、削除対象がオーナー以外の場合のみ）
            if (isCurrentUserOwner && !isOwner && userId != null)
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () {
                    print('DEBUG: Remove button tapped for user: $userId');
                    _showRemoveMemberDialog(context, userName, userId);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // ユーザー名
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            userName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOwner ? Colors.orange : themeColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// メンバー削除ダイアログを表示
  void _showRemoveMemberDialog(
      BuildContext context, String userName, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('$userName をスペースから削除しますか？\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // ダイアログを閉じる
              await _removeMember(context, userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// メンバーを削除
  Future<void> _removeMember(
      BuildContext context, String userId, String userName) async {
    try {
      print('DEBUG: Starting member removal for user: $userId');

      final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
      final currentUser = ref.read(currentUserProvider);

      if (currentSpace == null || currentUser == null) {
        print('DEBUG: Missing space or user info');
        Toast.show(context, 'スペース情報またはユーザー情報が取得できません');
        return;
      }

      print('DEBUG: Removing participant from space: ${currentSpace.id}');

      // スペース参加者を削除
      final spaceInfrastructure = SpaceInfrastructure();
      final success = await spaceInfrastructure.removeParticipant(
        spaceId: currentSpace.id,
        userId: userId,
        requesterId: currentUser.uid,
      );

      print('DEBUG: Remove participant result: $success');

      if (success) {
        if (context.mounted) {
          Toast.show(context, '$userName をスペースから削除しました');
          // 参加者リストを更新
          print('DEBUG: Refreshing participant list');
          await _loadParticipants();

          // プロバイダーも更新
          final spacesProvider = ref.read(firestoreSpacesProvider.notifier);
          await spacesProvider.reloadSpaces();
        }
      } else {
        if (context.mounted) {
          Toast.show(context, 'メンバーの削除に失敗しました');
        }
      }
    } catch (e) {
      print('DEBUG: Error removing member: $e');
      if (context.mounted) {
        Toast.show(context, 'メンバーの削除に失敗しました: $e');
      }
    }
  }

  /// LINEで招待コードを共有
  void _shareViaLine(BuildContext context) {
    if (_inviteCode == null) {
      Toast.show(context, '招待コードが取得できていません');
      return;
    }

    final message =
        '${widget.space.spaceName} スペースに参加しませんか？\n\n招待コード: $_inviteCode';
    final encodedMessage = Uri.encodeComponent(message);
    final lineUrl = 'https://line.me/R/msg/text/?$encodedMessage';

    launchUrl(Uri.parse(lineUrl)).catchError((e) {
      Toast.show(context, 'LINEの起動に失敗しました');
      return false;
    });
  }

  /// スペース削除ダイアログを表示
  void _showDeleteSpaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スペースを削除'),
        content: Text(
          '「${widget.space.spaceName}」を削除しますか？\n\n'
          'この操作は取り消せません。スペース内のすべてのデータが削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // ダイアログを閉じる

              try {
                // Firestoreスペースプロバイダーを使用してスペースを削除
                final firestoreSpaces = ref.read(firestoreSpacesProvider);
                if (firestoreSpaces != null) {
                  await ref
                      .read(firestoreSpacesProvider.notifier)
                      .deleteSpace(widget.space.id);
                } else {
                  // ローカルスペースプロバイダーの場合、userIdが必要
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser != null) {
                    await ref
                        .read(spacesProvider.notifier)
                        .deleteSpace(widget.space.id, currentUser.uid);
                  }
                }

                if (context.mounted) {
                  Toast.show(context, 'スペースを削除しました');
                  Navigator.pop(context); // 設定画面を閉じる
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('スペースの削除に失敗しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;

  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
