import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Logger _logger = Logger();

  AuthRepositoryImpl();

  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    final auth = _firebaseAuth;
    if (auth == null) return Stream.value(null);

    return auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        final db = _firestore;
        if (db == null) return null;
        final doc = await db.collection('users').doc(firebaseUser.uid).get();
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
    final auth = _firebaseAuth;
    final db = _firestore;

    if (auth == null || db == null) {
      // DEMO OFFLINE MODE BYPASS!
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate response delay
      return UserModel(
        uid: 'demo_cashier_01',
        email: email.isNotEmpty ? email : 'cashier@rathtech.com',
        name: 'Offline Demo Cashier',
        role: UserRole.cashier,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Email login completed but yielded null user body.");
      }

      final doc = await db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await auth.signOut();
        throw Exception("Access Denied: No authorized backend profile exists for this account.");
      }

      final userModel = UserModel.fromSnapshot(doc);
      
      if (!userModel.isActive) {
        await auth.signOut();
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
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final auth = _firebaseAuth;
    final db = _firestore;

    if (auth == null || db == null) {
      // Mock Offline Mode Creation
      await Future.delayed(const Duration(milliseconds: 1500));
      return UserModel(
        uid: 'offline_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Account creation failed: null user body.");
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await db.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e("Firebase signup exception: ${e.code}");
      throw Exception(_parseAuthErrorCode(e.code));
    } catch (e) {
      _logger.e("Non-firebase error during signup sequence: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  @override
  Future<UserEntity?> getCurrentUserProfile() async {
    final auth = _firebaseAuth;
    if (auth == null) return null;

    final currentUser = auth.currentUser;
    if (currentUser == null) return null;

    try {
      final db = _firestore;
      if (db == null) return null;

      final doc = await db.collection('users').doc(currentUser.uid).get();
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
