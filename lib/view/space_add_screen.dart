import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/view/space_invite_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:outi_log/services/analytics_service.dart';

class SpaceAddScreen extends ConsumerStatefulWidget {
  const SpaceAddScreen({super.key});

  @override
  ConsumerState<SpaceAddScreen> createState() => _SpaceAddScreenState();
}

class _SpaceAddScreenState extends ConsumerState<SpaceAddScreen> {
  // 定数
  static const int _inviteCodeLength = 8;
  static const String _inviteCodeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const String _lineShareUrl = 'https://line.me/R/msg/text/?';

  // フォーム関連
  final _formKey = GlobalKey<FormState>();
  final _spaceNameController = TextEditingController();

  // 状態管理
  List<SharedUser> _members = [];
  bool _isLoading = false;
  bool _isSpaceCreated = false;
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  @override
  void dispose() {
    _spaceNameController.dispose();
    super.dispose();
  }

  // MARK: - 初期化処理

  /// 現在のユーザーを初期化し、メンバーリストに追加
  void _initializeCurrentUser() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _members.add(SharedUser(
        name: 'あなた',
        address: currentUser.uid,
      ));
    }
  }

  // MARK: - 招待コード関連

  /// 8桁のランダムな招待コードを生成
  void _generateInviteCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final code = List.generate(_inviteCodeLength, (index) {
      final randomIndex = (random.hashCode + index) % _inviteCodeChars.length;
      return _inviteCodeChars[randomIndex];
    }).join();

    setState(() {
      _inviteCode = code;
    });
  }

  /// 招待コードをクリップボードにコピー
  void _copyInviteCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      Toast.show(context, '招待コードをコピーしました');
    }
  }

  /// LINEで招待コードを共有
  void _shareToLine() async {
    if (_inviteCode == null) return;

    final message = _buildShareMessage();
    final encodedMessage = Uri.encodeComponent(message);
    final lineUrl = '$_lineShareUrl$encodedMessage';

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

  /// 共有メッセージを構築
  String _buildShareMessage() {
    return 'おうちログに招待されました！\n\n'
        '招待コード: $_inviteCode\n\n'
        'このコードを使ってスペースに参加してください。';
  }

  // MARK: - スペース作成処理

  /// スペース作成のメイン処理
  Future<void> _createSpace() async {
    if (!_validateForm()) return;
    if (!_checkSpaceLimit()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _performSpaceCreation();
      if (success) {
        // スペース作成成功時にAnalyticsイベントを記録
        AnalyticsService().logSpaceCreate();
        _handleSpaceCreationSuccess();
      } else {
        _handleSpaceCreationFailure();
      }
    } catch (e) {
      _handleSpaceCreationError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// フォームのバリデーション
  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// スペース作成制限のチェック
  bool _checkSpaceLimit() {
    // Firestoreプロバイダーを優先的にチェック
    final firestoreSpaces = ref.read(firestoreSpacesProvider);
    final canCreate = firestoreSpaces?.canCreateSpace ??
        ref.read(spacesProvider.notifier).canCreateSpace;

    if (!canCreate) {
      Toast.show(context, 'スペース作成上限に達しています（無料版は2つまで）');
      return false;
    }
    return true;
  }

  /// スペース作成の実行
  Future<bool> _performSpaceCreation() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      Toast.show(context, 'ユーザー情報が取得できません');
      return false;
    }

    // Firestoreプロバイダーを使用してスペースを作成
    return await ref.read(firestoreSpacesProvider.notifier).addSpace(
          spaceName: _spaceNameController.text.trim(),
          userName: currentUser.displayName ?? '名無し',
          userEmail: currentUser.email ?? '',
        );
  }

  // 古いSpaceModel関連のメソッドは削除（Firestoreに移行済み）

  /// スペース作成成功時の処理
  void _handleSpaceCreationSuccess() {
    if (mounted) {
      Toast.show(context, 'スペースを作成しました');
      // 招待コード画面に遷移
      _navigateToInviteScreen();
    }
  }

  /// 招待コード画面に遷移
  void _navigateToInviteScreen() {
    // 作成されたスペースのIDを取得
    final firestoreSpaces = ref.read(firestoreSpacesProvider);
    final currentSpace = firestoreSpaces?.currentSpace;

    if (currentSpace != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SpaceInviteScreen(
            spaceId: currentSpace.id,
            spaceName: currentSpace.spaceName,
          ),
        ),
      );
    } else {
      // フォールバック：従来の招待コード表示
      _generateInviteCode();
      setState(() => _isSpaceCreated = true);
    }
  }

  /// スペース作成失敗時の処理
  void _handleSpaceCreationFailure() {
    if (mounted) {
      Toast.show(context, 'スペース作成に失敗しました');
    }
  }

  /// スペース作成エラー時の処理
  void _handleSpaceCreationError(dynamic error) {
    if (mounted) {
      Toast.show(context, 'エラーが発生しました: $error');
    }
  }

  // MARK: - UI Views
  @override
  Widget build(BuildContext context) {
    // Firestoreプロバイダーを優先的に使用
    final firestoreSpaces = ref.watch(firestoreSpacesProvider);
    final canCreateSpace = firestoreSpaces?.canCreateSpace ??
        ref.watch(spacesProvider.notifier).canCreateSpace;

    // ローディング中は制限チェックを無視（上限ページを表示しない）
    final shouldShowLimitReached = !_isLoading && !canCreateSpace;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: _buildBody(shouldShowLimitReached),
      ),
    );
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: themeColor,
      title: Text(
        _isSpaceCreated ? '招待コード' : 'スペースを作成',
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: _isSpaceCreated ? [_buildDoneButton()] : null,
    );
  }

  /// 完了ボタンを構築
  Widget _buildDoneButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        '完了',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  /// メインコンテンツを構築
  Widget _buildBody(bool shouldShowLimitReached) {
    if (shouldShowLimitReached) {
      return _buildLimitReachedView();
    }

    if (_isSpaceCreated) {
      return _buildInviteCodeView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return _buildCreateSpaceView();
  }

  /// ローディングビュー
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'スペースを作成中...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'しばらくお待ちください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// スペース作成制限に達した場合のビュー
  Widget _buildLimitReachedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'スペース作成上限に達しました',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '無料版では2つまでのスペース作成が可能です。\n'
              'より多くのスペースを作成するには、プレミアムプランにアップグレードしてください。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildUpgradeButton(),
            const SizedBox(height: 16),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  /// スペース作成フォームビュー
  Widget _buildCreateSpaceView() {
    // Firestoreプロバイダーを優先的に使用
    final firestoreSpaces = ref.watch(firestoreSpacesProvider);
    final remainingSpaces = firestoreSpaces?.remainingSpaces ??
        ref.watch(spacesProvider.notifier).remainingSpaces;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRemainingSpacesInfo(remainingSpaces),
          const SizedBox(height: 24),
          _buildSpaceForm(),
        ],
      ),
    );
  }

  /// 招待コード表示ビュー
  Widget _buildInviteCodeView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'スペースを作成しました！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '招待コードを共有して、\nメンバーを招待してください',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildInviteCodeCard(),
          const SizedBox(height: 24),
          _buildShareButtons(),
        ],
      ),
    );
  }

  // MARK: - UI Components

  /// 残りスペース数情報を表示
  Widget _buildRemainingSpacesInfo(int remainingSpaces) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '残りスペース作成可能数: $remainingSpaces個',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// スペース作成フォーム
  Widget _buildSpaceForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpaceNameField(),
          const SizedBox(height: 24),
          _buildMembersSection(),
          const SizedBox(height: 32),
          _buildCreateButton(),
        ],
      ),
    );
  }

  /// スペース名入力フィールド
  Widget _buildSpaceNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スペース名',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _spaceNameController,
          decoration: const InputDecoration(
            hintText: '例: マイホーム',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'スペース名を入力してください';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// メンバーセクション
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メンバー',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'あなたが自動的にオーナーとして追加されます',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ..._members.map((member) => _buildMemberCard(member)).toList(),
      ],
    );
  }

  /// メンバーカード
  Widget _buildMemberCard(SharedUser member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: themeColor,
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  member.address,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// スペース作成ボタン
  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createSpace,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'スペースを作成',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  /// 招待コードカード
  Widget _buildInviteCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            '招待コード',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _inviteCode ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _copyInviteCode,
            icon: const Icon(Icons.copy),
            label: const Text('コピー'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 共有ボタン
  Widget _buildShareButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareToLine,
            icon: const Icon(Icons.share),
            label: const Text('LINEで共有'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// アップグレードボタン
  Widget _buildUpgradeButton() {
    return ElevatedButton(
      onPressed: () => _showUpgradeDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: const Text(
        'プレミアムにアップグレード',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  /// 戻るボタン
  Widget _buildBackButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('戻る'),
    );
  }

  // MARK: - Dialogs

  /// アップグレードダイアログを表示
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムにアップグレード'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('プレミアムプランにアップグレードすると:'),
            SizedBox(height: 8),
            Text('• 無制限のスペース作成'),
            Text('• 高度な分析機能'),
            Text('• 優先サポート'),
            Text('• 広告なし'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 課金処理を実装
              Navigator.pop(context);
            },
            child: const Text('アップグレード'),
          ),
        ],
      ),
    );
  }
}
