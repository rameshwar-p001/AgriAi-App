import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;
import 'firestore_service.dart';
import 'connectivity_service.dart';

/// Authentication service using Firebase Auth
/// Handles user registration, login, logout and user state management
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  app_user.User? _currentUser;
  bool _isLoading = false;
  int _currentAttempt = 0;
  final int _maxAttempts = 3;

  /// Constructor - listen to auth state changes
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Get current user
  app_user.User? get currentUser => _currentUser;
  
  /// Get current user ID from Firebase
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null && _currentUser != null;
  
  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get current retry attempt
  int get currentAttempt => _currentAttempt;
  
  /// Get max retry attempts
  int get maxAttempts => _maxAttempts;
  
  /// Check network connectivity before authentication
  Future<String?> _checkConnectivity() async {
    final hasInternet = await ConnectivityService.hasInternetConnection();
    if (!hasInternet) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    final canReachFirebase = await ConnectivityService.canReachFirebase();
    if (!canReachFirebase) {
      return 'Cannot reach Firebase services. Please check your connection.';
    }
    
    return null; // No connectivity issues
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      // User is signed in, load user data from Firestore
      _currentUser = await _firestoreService.getUser(firebaseUser.uid);
      if (_currentUser == null) {
        // Create new user in Firestore if doesn't exist
        _currentUser = app_user.User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          email: firebaseUser.email ?? '',
          soilType: 'alluvial',
          preferredCrops: [],
          userType: 'farmer',
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(_currentUser!);
      }
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _currentAttempt = 0;
      notifyListeners();
      
      // Check connectivity first
      final connectivityError = await _checkConnectivity();
      if (connectivityError != null) {
        debugPrint('Connectivity check failed: $connectivityError');
        throw Exception(connectivityError);
      }
      
      // Try authentication with shorter timeout and retry logic
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _currentAttempt = attempt;
          notifyListeners();
          
          await _auth.signInWithEmailAndPassword(email: email, password: password)
              .timeout(const Duration(seconds: 3)); // Ultra-fast feedback for demo fallback
          return true;
        } catch (e) {
          debugPrint('Authentication attempt $attempt failed: $e');
          
          // Handle specific Firebase errors
          if (e.toString().contains('Too many attempts')) {
            debugPrint('Too many authentication attempts detected - waiting longer');
            await Future.delayed(Duration(seconds: attempt * 3)); // Longer delay for rate limiting
          } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
            debugPrint('Network issue detected - shorter retry delay');
            await Future.delayed(Duration(seconds: attempt * 2));
          } else {
            if (attempt == 3) rethrow; // Rethrow on final attempt for other errors
            await Future.delayed(Duration(seconds: attempt * 2));
          }
          
          if (attempt == 3) rethrow; // Rethrow on final attempt
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Network or timeout error during sign in: $e');
      return false;
    } finally {
      _isLoading = false;
      _currentAttempt = 0;
      notifyListeners();
    }
  }

  /// Find email associated with phone number in Firestore
  Future<String?> findEmailByPhoneNumber(String phoneNumber) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding email by phone: $e');
      return null;
    }
  }

  /// Sign in with phone number and password
  /// This method finds the email associated with the phone number
  /// and then uses Firebase email+password authentication
  Future<bool> signInWithPhoneAndPassword(String phoneNumber, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, find the email associated with this phone number
      final email = await findEmailByPhoneNumber(phoneNumber)
          .timeout(const Duration(seconds: 10));
      
      if (email == null) {
        debugPrint('No email found for phone number: $phoneNumber');
        return false;
      }

      // Use the found email to sign in with Firebase (with retry)
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await _auth.signInWithEmailAndPassword(email: email, password: password)
              .timeout(const Duration(seconds: 3)); // Ultra-fast feedback for demo fallback
          return true;
        } catch (e) {
          debugPrint('Phone auth attempt $attempt failed: $e');
          
          // Handle specific errors
          if (e.toString().contains('Too many attempts')) {
            debugPrint('Too many phone auth attempts - waiting longer');
            await Future.delayed(Duration(seconds: attempt * 3));
          } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
            await Future.delayed(Duration(seconds: attempt * 2));
          } else {
            if (attempt == 3) rethrow;
            await Future.delayed(Duration(seconds: attempt * 2));
          }
          
          if (attempt == 3) rethrow;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Phone sign in error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Network or timeout error during phone sign in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register with email and password
  Future<bool> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try registration with retry logic
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: email, 
            password: password
          ).timeout(const Duration(seconds: 3)); // Ultra-fast feedback for demo fallback          // Update display name
          await result.user?.updateDisplayName(name)
              .timeout(const Duration(seconds: 5));
          
          return true;
        } catch (e) {
          debugPrint('Registration attempt $attempt failed: $e');
          
          // Handle specific errors
          if (e.toString().contains('Too many attempts')) {
            debugPrint('Too many registration attempts - waiting longer');
            await Future.delayed(Duration(seconds: attempt * 3));
          } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
            await Future.delayed(Duration(seconds: attempt * 2));
          } else {
            if (attempt == 3) rethrow;
            await Future.delayed(Duration(seconds: attempt * 2));
          }
          
          if (attempt == 3) rethrow;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Network or timeout error during registration: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register with email, password, name and optional phone
  Future<bool> registerWithEmailAndPasswordAndPhone(String email, String password, String name, String? phone) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Update display name
      await result.user?.updateDisplayName(name);
      
      // Save additional user data to Firestore if phone is provided
      if (phone != null && phone.isNotEmpty && result.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store verification ID for later use
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return true;
    } catch (e) {
      print('OTP send error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _verificationId;

  /// Verify OTP and sign in
  Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) return false;
      
      _isLoading = true;
      notifyListeners();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('OTP verification error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(app_user.User updatedUser) async {
    try {
      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return false;
    }
  }

    /// Demo sign-in for poor connectivity scenarios
  Future<void> signInDemo() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Simulate demo user creation without Firebase
      final demoUser = app_user.User(
        id: 'demo_user_123',
        name: 'Demo User',
        email: 'demo@agriapp.com',
        soilType: 'Loamy',
        preferredCrops: ['Rice', 'Wheat', 'Corn'],
        userType: 'farmer',
        createdAt: DateTime.now(),
      );
      
      _currentUser = demoUser;
      notifyListeners();
    } catch (e) {
      throw Exception('Demo mode error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
