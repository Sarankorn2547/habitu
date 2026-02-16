import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Login, 1 = Register
  int _selectedIndex = 0;
  
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Action: Submit Form
  Future<void> _submitForm() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    // Check Confirm Password for Register
    if (_selectedIndex == 1) {
      if (password != _confirmPassController.text.trim()) {
        _showError("Passwords do not match");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedIndex == 0) {
        // --- LOGIN ---
        final user = await authService.signIn(email, password);
        if (user == null) {
          throw Exception("Login failed. Please check your email and password.");
        }
      } else {
        // --- REGISTER ---
        final user = await authService.signUp(email, password);
        if (user == null) {
          throw Exception("Registration failed. Please try again.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Account created! Logging you in...")),
          );
        }
      }
      // Successful login/register will trigger stream in main.dart to redirect
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Action: Forgot Password
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("Please enter your email to reset password");
      return;
    }
    
    try {
      await Provider.of<AuthService>(context, listen: false).sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to $email"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError("Failed to send reset email: ${e.toString()}");
    }
  }

  void _showError(String message) {
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLogin = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Icon(Icons.emoji_events_rounded, size: 80, color: colorScheme.primary),
              SizedBox(height: 16),
              Text(
                "HABIT U",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                "Level up your life",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 48),

              // --- Title (Optional, showing current mode) ---
              Text(
                isLogin ? "Welcome Back" : "Create Account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 24),

              // --- Email ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "hero@example.com",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
              ),
              SizedBox(height: 16),

              // --- Password ---
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
              ),

              // --- Confirm Password (Register Only) ---
              if (!isLogin) ...[
                SizedBox(height: 16),
                TextField(
                  controller: _confirmPassController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                  ),
                ),
              ],

              SizedBox(height: 32),

              // --- Action Button ---
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLogin ? "Login" : "Sign Up",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // --- Bottom Links ---
              if (isLogin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1; // Switch to Register
                          _showError(""); // Clear errors
                        });
                      },
                      child: Text("Register"),
                    ),
                    TextButton(
                      onPressed: _forgotPassword,
                      child: Text("Forgot Password?"),
                    ),
                  ],
                )
              else
                // Back to Login link for Register mode
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0; // Switch to Login
                        _showError(""); // Clear errors
                      });
                    },
                    child: Text("Already have an account? Login"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
