import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/utils/validate.dart';
import 'package:outi_log/view/auth/create_send_email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:outi_log/services/analytics_service.dart';
import 'package:outi_log/services/remote_notification_service.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  late final AuthController _authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? usernameError;

  String selectedGender = '秘密';
  File? selectedImage;
  bool isLoading = false;

  final List<String> genderOptions = ['男', '女', '秘密'];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      AuthInfrastructure(),
      LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
      UserFirestoreInfrastructure(),
      StorageInfrastructure(),
      RemoteNotificationService(),
    );

    // アカウント作成画面の表示を記録
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logScreenView(screenName: 'create_account');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      emailError = Validate.validateEmail(_emailController.text);
      passwordError = Validate.validatePassword(_passwordController.text);
      usernameError = Validate.validateUsername(_usernameController.text);
      confirmPasswordError = Validate.validateConfirmPassword(
          _passwordController.text, _confirmPasswordController.text);
    });
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              if (selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('画像を削除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, '画像の選択に失敗しました: $e');
      }
    }
  }

  Future<void> _createAccount() async {
    UserCredential? userCredential;
    _validateFields();

    if (emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        usernameError == null) {
      setState(() {
        isLoading = true;
      });
      userCredential = await _authController.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        context: context,
        setState: () {
          setState(() {
            isLoading = false;
          });
        },
        profileImage: selectedImage != null ? XFile(selectedImage!.path) : null,
      );

      if (userCredential != null) {
        // アカウント作成成功時にAnalyticsイベントを記録
        AnalyticsService().logSignUp(signUpMethod: 'email');

        Toast.show(context, '認証メールを送信しました。');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateSendEmailScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'アカウント作成',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // ウェルカムメッセージ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.1),
                    themeColor.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 48,
                    color: themeColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'おうちログへようこそ！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'アカウントを作成して、家族の生活を管理しましょう',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // アカウントアイコン選択
            _buildIconSelection(),

            const SizedBox(height: 24),

            // 基本情報セクション
            _buildBasicInfoSection(),

            const SizedBox(height: 24),

            // アカウント情報セクション
            _buildAccountInfoSection(),

            const SizedBox(height: 32),

            // 登録ボタン
            _buildCreateAccountButton(),

            const SizedBox(height: 20),

            // ログイン画面へのリンク
            _buildLoginLink(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'プロフィール画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _selectImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: themeColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(57),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                        width: 114,
                        height: 114,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: themeColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '画像を選択',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            selectedImage != null ? 'タップして変更' : 'タップして画像を選択',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本情報',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // ユーザー名
        _buildTextField(
          'ユーザー名',
          _usernameController,
          Icons.person_outline,
          onChanged: (value) {
            setState(() {
              usernameError = Validate.validateUsername(value);
            });
          },
          errorText: usernameError,
        ),

        const SizedBox(height: 16),

        // 性別選択
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'アカウント情報',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // メールアドレス
        _buildTextField(
          'メールアドレス',
          _emailController,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            setState(() {
              emailError = Validate.validateEmail(value);
            });
          },
          errorText: emailError,
        ),

        const SizedBox(height: 16),

        // パスワード
        _buildTextField(
          'パスワード',
          _passwordController,
          Icons.lock_outline,
          isPassword: true,
          onChanged: (value) {
            setState(() {
              passwordError = Validate.validatePassword(value);
              confirmPasswordError = Validate.validateConfirmPassword(
                  value, _confirmPasswordController.text);
            });
          },
          errorText: passwordError,
        ),

        const SizedBox(height: 16),

        // 確認用パスワード
        _buildTextField(
          '確認用パスワード',
          _confirmPasswordController,
          Icons.lock_outline,
          isPassword: true,
          onChanged: (value) {
            setState(() {
              confirmPasswordError = Validate.validateConfirmPassword(
                  _passwordController.text, value);
            });
          },
          errorText: confirmPasswordError,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          errorText: errorText,
          errorStyle: const TextStyle(fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: themeColor),
          items: genderOptions.map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Row(
                children: [
                  Icon(
                    gender == '男'
                        ? Icons.male
                        : gender == '女'
                            ? Icons.female
                            : Icons.visibility_off,
                    color: themeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    gender,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedGender = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    final bool isFormValid = emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        usernameError == null &&
        _usernameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isFormValid
            ? LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isFormValid ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFormValid
            ? [
                BoxShadow(
                  color: themeColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading || !isFormValid
            ? null
            : () {
                _createAccount();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'アカウント作成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'すでにアカウントをお持ちですか？',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              'ログイン',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
