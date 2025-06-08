import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Sign in cancelled by user';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if profile exists
      final hasProfile = await isUserProfileComplete();
      if (!hasProfile) {
        // Create a basic profile if it doesn't exist
        final user = userCredential.user!;
        final profile = {
          'uid': user.uid,
          'email': user.email,
          'fullName': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(user.uid).set(profile);
      }

      return userCredential;
    } catch (e) {
      throw 'Failed to sign in with Google: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson());
    } catch (e) {
      throw 'Failed to create user profile: ${e.toString()}';
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      throw 'Failed to get user profile: ${e.toString()}';
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // Update only the fields that can be modified
      final updates = {
        'fullName': profile.fullName,
        'age': profile.age,
        'gender': profile.gender,
        'height': profile.height,
        'weight': profile.weight,
        'bloodGroup': profile.bloodGroup,
        'allergies': profile.allergies,
        'medicalConditions': profile.medicalConditions,
        'photoUrl': profile.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(updates);
    } catch (e) {
      throw 'Failed to update user profile: ${e.toString()}';
    }
  }

  Future<bool> isUserProfileComplete() async {
    try {
      if (currentUser == null) {
        return false;
      }

      final profile = await getUserProfile(currentUser!.uid);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromJson(doc.data()!) : null);
  }
} 