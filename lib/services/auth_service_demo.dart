import 'dart:async';
import '../models/user.dart' as app_user;

/// Authentication service for AgriAI app - Demo Version
/// Works without Firebase for demo purposes
class AuthService {
  // Demo mode variables
  final StreamController<app_user.User?> _authController = StreamController<app_user.User?>.broadcast();
  app_user.User? _currentUser;
  bool _isLoggedIn = false;

  AuthService() {
    // Initialize with no user
    _authController.add(null);
  }

  /// Get current user stream
  Stream<app_user.User?> get authStateChanges => _authController.stream;

  /// Get current user
  app_user.User? get currentUser => _currentUser;

  /// Get current user ID
  String? get currentUserId => _currentUser?.id;

  /// Check if user is logged in
  bool get isLoggedIn => _isLoggedIn;

  /// Sign in with email and password (Demo version)
  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Demo login - accept any email/password
      final demoUser = app_user.User(
        id: 'demo_user_123',
        name: 'Demo Farmer',
        email: email,
        soilType: 'loamy',
        preferredCrops: ['Rice', 'Wheat', 'Corn'],
        userType: 'farmer',
        createdAt: DateTime.now(),
      );
      
      _currentUser = demoUser;
      _isLoggedIn = true;
      _authController.add(demoUser);
      
      return demoUser;
    } catch (e) {
      print('Demo sign in error: $e');
      return null;
    }
  }

  /// Register with email and password (Demo version)
  Future<app_user.User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
    required String location,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final newUser = app_user.User(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        soilType: 'Clay',
        preferredCrops: ['Tomato', 'Potato'],
        userType: userType,
        createdAt: DateTime.now(),
      );
      
      _currentUser = newUser;
      _isLoggedIn = true;
      _authController.add(newUser);
      
      return newUser;
    } catch (e) {
      print('Demo registration error: $e');
      return null;
    }
  }

  /// Sign in with Google (Demo version)
  Future<app_user.User?> signInWithGoogle() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final demoUser = app_user.User(
        id: 'google_demo_user_123',
        name: 'Google Demo User',
        email: 'demo@gmail.com',
        soilType: 'Sandy',
        preferredCrops: ['Cotton', 'Sugarcane'],
        userType: 'farmer',
        createdAt: DateTime.now(),
      );
      
      _currentUser = demoUser;
      _isLoggedIn = true;
      _authController.add(demoUser);
      
      return demoUser;
    } catch (e) {
      print('Demo Google sign in error: $e');
      return null;
    }
  }

  /// Sign out (Demo version)
  Future<void> signOut() async {
    try {
      _currentUser = null;
      _isLoggedIn = false;
      _authController.add(null);
    } catch (e) {
      print('Demo sign out error: $e');
    }
  }

  /// Send password reset email (Demo version)
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      print('Demo: Password reset email sent to $email');
    } catch (e) {
      print('Demo password reset error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  /// Update password (Demo version)
  Future<void> updatePassword({required String newPassword}) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      print('Demo: Password updated successfully');
    } catch (e) {
      print('Demo password update error: $e');
      throw Exception('Failed to update password');
    }
  }

  /// Dispose resources
  void dispose() {
    _authController.close();
  }
}