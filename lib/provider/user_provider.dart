import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/user_model.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/provider/auth_provider.dart';

final userFirestoreInfrastructureProvider =
    Provider<UserFirestoreInfrastructure>((ref) {
  return UserFirestoreInfrastructure();
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final userInfrastructure = ref.read(userFirestoreInfrastructureProvider);
  try {
    return await userInfrastructure.getUser(currentUser.uid);
  } catch (e) {
    print('Error getting user model: $e');
    return null;
  }
});

final cachedUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final userInfrastructure = ref.read(userFirestoreInfrastructureProvider);
  try {
    // まずキャッシュから取得を試行
    final cachedUser = await userInfrastructure.getCachedUser(currentUser.uid);
    if (cachedUser != null) {
      return cachedUser;
    }

    // キャッシュにない場合はFirestoreから取得
    return await userInfrastructure.getUser(currentUser.uid);
  } catch (e) {
    print('Error getting cached user model: $e');
    return null;
  }
});
