import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authStateProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
