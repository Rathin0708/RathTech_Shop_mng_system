import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Stream to watch auth state changes continuously
  Stream<UserEntity?> get authStateChanges;

  // Email and Password Login
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // User Sign Out
  Future<void> signOut();

  // Fetch current local profile snapshot
  Future<UserEntity?> getCurrentUserProfile();
}
