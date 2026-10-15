import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart'
    show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show AuthorizationErrorCode, SignInWithAppleAuthorizationException;

import 'package:balance_forward/core/services/auth/auth_service.dart';
import 'package:balance_forward/design_system/bf_theme.dart';

/// Sign-in screen backed by [AuthService] — inject the real
/// [FirebaseAuthService] in the app and [FakeAuthService] in tests/widget
/// previews. Google is Android-only, Apple is iOS-only: a deliberate
/// one-provider-per-platform split matching Modulo Squares' auth design, not
/// an oversight. Do not "fix" this to be cross-platform without checking
/// with the app owner first.
///
/// Unlike [AuthService.signInWithGoogle]/[signInWithApple] themselves,
/// cancellation-swallowing and friendly error messages live here rather than
/// in the service, since [FirebaseAuthService] just lets exceptions
/// propagate.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    this.onAuthenticationComplete,
  });

  final AuthService authService;

  /// Called after a successful sign-in. The app's top-level router normally
  /// relies on [AuthService.authStateChanges] instead of this callback.
  final VoidCallback? onAuthenticationComplete;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _EmailMode { signIn, signUp }

class _LoginScreenState extends State<LoginScreen> {
  bool _authInProgress = false;
  _EmailMode _emailMode = _EmailMode.signIn;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _emailError;
  String? _emailInfo;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showAuthError(BuildContext context, Object error) {
    if (!context.mounted) return;
    String message;
    if (kDebugMode) {
      if (error is FirebaseAuthException) {
        message = '${error.message ?? error.code}\n\n(code: ${error.code})';
      } else {
        message = error.toString();
      }
    } else {
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'user-disabled':
            message = 'This account has been disabled. Please contact support.';
          case 'too-many-requests':
            message = 'Too many attempts. Please wait a moment and try again.';
          case 'network-request-failed':
            message =
                'No internet connection. Please check your network and try again.';
          default:
            message = 'Sign in failed. Please try again.';
        }
      } else {
        message = 'Sign in failed. Please try again.';
      }
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign-in failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      await widget.authService.signInWithGoogle();
      widget.onAuthenticationComplete?.call();
    } catch (e) {
      if (e is PlatformException && e.code == 'sign_in_canceled') return;
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      await widget.authService.signInWithApple();
      widget.onAuthenticationComplete?.call();
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  String _friendlyEmailError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email — try signing in instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _handleEmailSubmit() async {
    if (_authInProgress) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_emailMode == _EmailMode.signUp &&
        password != _confirmPasswordController.text) {
      setState(() {
        _emailError = 'Passwords do not match.';
        _emailInfo = null;
      });
      return;
    }

    setState(() {
      _authInProgress = true;
      _emailError = null;
      _emailInfo = null;
    });
    try {
      if (_emailMode == _EmailMode.signIn) {
        await widget.authService.signInWithEmail(email, password);
      } else {
        await widget.authService.signUpWithEmail(email, password);
      }
      widget.onAuthenticationComplete?.call();
    } catch (e) {
      if (mounted) setState(() => _emailError = _friendlyEmailError(e));
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError =
            'Enter your email above first, then tap "Forgot password?"';
        _emailInfo = null;
      });
      return;
    }
    setState(() {
      _authInProgress = true;
      _emailError = null;
      _emailInfo = null;
    });
    try {
      await widget.authService.sendPasswordResetEmail(email);
      if (mounted) {
        setState(
          () => _emailInfo = 'Password reset email sent — check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _emailError = _friendlyEmailError(e));
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.canvas,
      body: SafeArea(
        child: BfResponsiveBody(
          maxContentWidth: BfLayout.formMaxWidth,
          includeGutter: true,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: BfColors.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const _CompoundingArcMark(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Balance Forward',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: BfColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Good choices compound.',
                  style: TextStyle(fontSize: 15, color: BfColors.muted),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Sign in to manage your classroom or family account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: BfColors.muted),
                ),
                const SizedBox(height: 28),
                if (defaultTargetPlatform == TargetPlatform.android) ...[
                  _AuthButton(
                    key: const Key('googleSignInButton'),
                    label: 'Sign in with Google',
                    icon: Icons.g_mobiledata,
                    onPressed: _authInProgress
                        ? null
                        : () => _signInWithGoogle(context),
                  ),
                  const SizedBox(height: 12),
                ],
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  _AuthButton(
                    key: const Key('appleSignInButton'),
                    label: 'Sign in with Apple',
                    icon: Icons.apple,
                    onPressed: _authInProgress
                        ? null
                        : () => _signInWithApple(context),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider(color: BfColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or',
                        style: TextStyle(color: BfColors.muted),
                      ),
                    ),
                    const Expanded(child: Divider(color: BfColors.border)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('emailField'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: BfColors.ink),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('passwordField'),
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(color: BfColors.ink),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      key: const Key('togglePasswordVisibility'),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: BfColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
                if (_emailMode == _EmailMode.signUp) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('confirmPasswordField'),
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    style: const TextStyle(color: BfColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      suffixIcon: IconButton(
                        key: const Key('toggleConfirmPasswordVisibility'),
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: BfColors.muted,
                        ),
                        onPressed: () => setState(
                          () => _confirmPasswordVisible =
                              !_confirmPasswordVisible,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _AuthButton(
                  key: const Key('emailSubmitButton'),
                  label: _emailMode == _EmailMode.signIn
                      ? 'Sign In'
                      : 'Create Account',
                  icon: Icons.email,
                  onPressed: _authInProgress ? null : _handleEmailSubmit,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      key: const Key('toggleModeButton'),
                      onPressed: () => setState(() {
                        _emailMode = _emailMode == _EmailMode.signIn
                            ? _EmailMode.signUp
                            : _EmailMode.signIn;
                        _emailError = null;
                        _emailInfo = null;
                      }),
                      child: Text(
                        _emailMode == _EmailMode.signIn
                            ? 'Create an account'
                            : 'Already have an account?',
                        style: const TextStyle(
                          color: BfColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('forgotPasswordButton'),
                      onPressed: _authInProgress ? null : _handleForgotPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: BfColors.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_emailError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _emailError!,
                    style: const TextStyle(
                      color: BfColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_emailInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _emailInfo!,
                    style: const TextStyle(
                      color: BfColors.brandBright,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompoundingArcMark extends StatelessWidget {
  const _CompoundingArcMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CompoundingArcPainter(),
      size: const Size.square(70),
    );
  }
}

class _CompoundingArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 160;
    final scaleY = size.height / 120;
    canvas.scale(scaleX, scaleY);

    void drawArc(Path path, Color color, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    drawArc(
      Path()
        ..moveTo(14, 100)
        ..cubicTo(65, 102, 113, 94, 146, 72),
      BfColors.canvas,
      22,
    );
    drawArc(
      Path()
        ..moveTo(24, 70)
        ..cubicTo(70, 71, 110, 62, 140, 43),
      BfColors.mintStrong,
      17,
    );
    drawArc(
      Path()
        ..moveTo(54, 39)
        ..cubicTo(87, 38, 115, 30, 135, 14),
      const Color(0xFFF2B544),
      12,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: BfColors.brand,
          foregroundColor: BfColors.onDark,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: BfColors.onDark),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: BfColors.onDark, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
