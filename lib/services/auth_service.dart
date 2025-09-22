import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;
  
  // Phone authentication for guest booking
  // ...existing code...
  // Phone authentication for guest booking
  static Future<String> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onVerificationCompleted,
    Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      String fullPhoneNumber = '+91$phoneNumber'; // Assuming Indian numbers

      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: onVerificationCompleted ??
            (PhoneAuthCredential credential) async {
              // Auto verification completed
            },
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout ??
            (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      return 'OTP sent successfully';
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }
// ...existing code...
  
  // Verify OTP for phone authentication
  static Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Create user profile if new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await createUserProfile(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      throw Exception('Invalid OTP: $e');
    }
  }
  
  // Email/Password Sign In
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }
  
  // Email/Password Sign Up
  static Future<UserCredential> signUpWithEmail(
    String email, 
    String password, 
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Create user profile
      await createUserProfile(userCredential.user!, name: name);
      
      return userCredential;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  
  // Create user profile in Firestore
  static Future<void> createUserProfile(User user, {String? name}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'emergencyContacts': [],
        'favoriteRoutes': [],
        'totalTrips': 0,
        'totalSpent': 0.0,
        'ratings': {
          'asPassenger': 5.0,
          'totalRatings': 0,
        },
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }
  
  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update(data);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
  
  // Delete account
  static Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(currentUser!.uid).delete();
        
        // Delete user account
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
