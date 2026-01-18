import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  final Color brandBlue = const Color(0xFF005CEE);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = AuthService();
    final result = await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    // 3. Handle the result
    if (result['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacementNamed(context, '/my-prompts');
    } else {
      setState(() {
        if (result['message'].contains('401')) {
          _errorMessage = 'Invalid email or password. Please try again.';
        } else {
          _errorMessage = result['message'] ?? 'An unknown error occurred';
        }
      });

      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(_errorMessage!)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // clientId: '942310671437-n8mgsjlurld74pq08m4lr3fc94ibghqb.apps.googleusercontent.com',
        serverClientId: '942310671437-h59u8uhf8cecs7pj2v5715nd2a3s8pat.apps.googleusercontent.com',
        scopes: ['email'],
      );

      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get authentication token';
        });
        return;
      }

      final authService = AuthService();
      final result = await authService.googleLogin(idToken);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Google login successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacementNamed(context, '/my-prompts');
      } else {
        setState(() => _errorMessage = result['message'] ?? 'An unknown error occurred');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMessage!)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Google login fail!!');
      setState(() => _errorMessage = 'Google login fail!!');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 200, // Adjust size as needed
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('picture/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your account to continue',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email
                _buildInputLabel('Email Address'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter your email address',
                ),

                const SizedBox(height: 24),

                // Password
                _buildInputLabel('Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  isPassword: true,
                ),

                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Divider + Google + Create account...
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black87,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        print("Navigating to register..."); // For debugging
                        Navigator.pushNamed(context, '/register');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4), // Small padding for hit area
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Create one',
                        style: TextStyle(
                          color: brandBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF005CEE), width: 2),
        ),
      ),
    );
  }
}