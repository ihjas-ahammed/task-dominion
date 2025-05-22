import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (_isLogin) {
        await gameProvider.loginUser(_email, _password);
      } else {
        await gameProvider.signupUser(_email, _password);
      }
      // Auth state change will handle navigation in MyApp or GameProvider listener
    } catch (e) {
      print("[LoginScreen] Auth Error: $e"); // DEBUG
      setState(() {
        if (e is FirebaseAuthException) {
          _error = e.message ?? "An unknown Firebase authentication error occurred.";
          // Example of more specific error messages:
          // switch (e.code) {
          //   case 'user-not-found':
          //     _error = 'No user found for that email.';
          //     break;
          //   case 'wrong-password':
          //     _error = 'Wrong password provided for that user.';
          //     break;
          //   case 'email-already-in-use':
          //     _error = 'An account already exists for that email.';
          //     break;
          //   case 'weak-password':
          //     _error = 'The password provided is too weak.';
          //     break;
          //   case 'invalid-email':
          //     _error = 'The email address is not valid.';
          //     break;
          //   // Add more cases as needed based on Firebase Auth error codes
          //   default:
          //     _error = e.message ?? "An unknown Firebase error occurred.";
          // }
        } else {
          _error = "An unexpected error occurred. Please try again.";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.fhBgDark, // Use the new dark background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child:
              // Add a ConstrainedBox to limit the width for desktop
              ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Max width of 400 pixels
            child: Card(
              color: AppTheme.fhBgMedium, // Slightly lighter card background
              elevation: 0, // Flatter design
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: AppTheme.fhBorderColor, width: 1.5), // Themed border
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(MdiIcons.shieldCrownOutline, size: 56, color: AppTheme.fhAccentTeal), // Themed Icon
                      const SizedBox(height: 16),
                      Text(
                        'TASK DOMINION',
                        style: theme.textTheme.displaySmall?.copyWith( // Use displaySmall for prominent title
                          color: AppTheme.fhAccentTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Secure Login' : 'Create Account', // Updated subtitle
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.fhTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(MdiIcons.emailOutline, color: theme.inputDecorationTheme.labelStyle?.color, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.fhTextPrimary, fontFamily: AppTheme.fontBody),
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email.';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(MdiIcons.lockOutline, color: theme.inputDecorationTheme.labelStyle?.color, size: 20),
                        ),
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.fhTextPrimary, fontFamily: AppTheme.fontBody),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) => _password = value!,
                      ),
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _error,
                            style: const TextStyle(color: AppTheme.fhAccentRed, fontSize: 12, fontFamily: AppTheme.fontBody),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator(color: AppTheme.fhAccentTeal)
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                        ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _error = '';
                          });
                        },
                        child: Text(
                          _isLogin ? 'Need an account? Sign Up' : 'Already have an account? Login',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}