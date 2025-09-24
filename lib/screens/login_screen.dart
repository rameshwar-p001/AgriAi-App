import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // For registration
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                'AgriAI - Smart Farming Assistant',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (!_isLogin)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_box),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 16),

              if (!_isLogin)
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              if (!_isLogin) const SizedBox(height: 16),

              TextField(
                controller: _emailOrPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return ElevatedButton(
                      onPressed: authService.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authService.isLoading
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                if (authService.currentAttempt > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Attempt ${authService.currentAttempt}/${authService.maxAttempts}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Text(_isLogin ? 'Login' : 'Register'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),

              // DEMO MODE SECTION
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off,
                          color: Colors.orange, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Network Issues?',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _enterDemoMode(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          '🚀 TRY DEMO MODE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Works offline - No internet required!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle Login/Register
  Future<void> _handleSubmit() async {
    try {
      final input = _emailOrPhoneController.text.trim();
      final password = _passwordController.text.trim();

      if (input.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      final isEmail = input.contains('@');
      if (!isEmail &&
          !RegExp(r'^[\+]?[1-9][\d]{0,15}$').hasMatch(input)) {
        throw Exception('Please enter a valid email or phone number');
      }

      bool success = false;
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        if (isEmail) {
          success =
              await authService.signInWithEmailAndPassword(input, password);
        } else {
          success =
              await authService.signInWithPhoneAndPassword(input, password);
        }
      } else {
        if (!isEmail) {
          throw Exception(
              'Please enter a valid email address for registration');
        }
        success =
            await authService.registerWithEmailAndPasswordAndPhone(
          input,
          password,
          _nameController.text.trim(),
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  _isLogin ? 'Login successful!' : 'Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Login failed. Please check your internet connection and credentials, then try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error: $e';
        if (e.toString().contains('network') ||
            e.toString().contains('timeout') ||
            e.toString().contains('resolve host')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('Too many attempts')) {
          errorMessage =
              'Too many login attempts. Please wait a few minutes and try again.';
        } else if (e.toString().contains('user-not-found')) {
          errorMessage =
              'No account found with this email/phone. Please register first.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage =
              'Email already registered. Please try logging in instead.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// DEMO MODE for offline usage
  Future<void> _enterDemoMode() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final shouldEnter = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Demo Mode'),
          content: const Text(
            'Demo Mode allows you to explore the app features without requiring internet connectivity.\n\n'
            'Note: Your data will not be saved and some features may be limited.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange),
              child: const Text('Enter Demo Mode'),
            ),
          ],
        ),
      );

      if (shouldEnter == true) {
        await authService.signInDemo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Welcome to Demo Mode! Explore the app features.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error entering Demo Mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
