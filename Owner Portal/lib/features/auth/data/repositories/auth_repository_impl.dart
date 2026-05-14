import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        // Attempt to fetch complementary user record from firestore collection
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          _logger.w("Firestore record missing for auth account ${firebaseUser.uid}");
          return null;
        }
        return UserModel.fromSnapshot(doc);
      } catch (e) {
        _logger.e("Exception fetching user stream payload: $e");
        return null;
      }
    });
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Email login completed but yielded null user body.");
      }

      // Verify corresponding Firestore profile payload exists
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Sign them right back out to enforce security
        await _firebaseAuth.signOut();
        throw Exception("Access Denied: No authorized backend profile exists for this account.");
      }

      final userModel = UserModel.fromSnapshot(doc);
      
      if (!userModel.isActive) {
        await _firebaseAuth.signOut();
        throw Exception("Access Denied: This account status is currently marked as inactive.");
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e("Firebase login exception: ${e.code}");
      throw Exception(_parseAuthErrorCode(e.code));
    } catch (e) {
      _logger.e("Non-firebase error during login sequence: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUserProfile() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    } catch (e) {
      _logger.e("Error fetching profile on-demand: $e");
      return null;
    }
  }

  String _parseAuthErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The formatting of this email address is invalid.';
      case 'user-disabled':
        return 'This user identity block has been administrative disabled.';
      case 'user-not-found':
        return 'No registered user records associated with this email address.';
      case 'wrong-password':
        return 'The credentials supplied do not match system records.';
      case 'network-request-failed':
        return 'Internet connection dropped. Please check connectivity and retry.';
      default:
        return 'Authentication failed. Reason code: $code';
    }
  }
}
