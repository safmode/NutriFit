import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final firstC = TextEditingController();
  final lastC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirestoreService();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    firstC.dispose();
    lastC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  bool _isEmailValid(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  String _authErrorMsg(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled.';
      default:
        return e.message ?? 'Authentication error (${e.code})';
    }
  }

  bool _validate() {
    final email = emailC.text.trim();
    final pass = passC.text;
    final confirm = confirmC.text;

    if (firstC.text.trim().isEmpty) {
      _snack('First name is required.');
      return false;
    }
    if (lastC.text.trim().isEmpty) {
      _snack('Last name is required.');
      return false;
    }
    if (email.isEmpty) {
      _snack('Email is required.');
      return false;
    }
    if (!_isEmailValid(email)) {
      _snack('Enter a valid email.');
      return false;
    }
    if (pass.isEmpty) {
      _snack('Password is required.');
      return false;
    }
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters.');
      return false;
    }
    if (pass != confirm) {
      _snack('Passwords do not match.');
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;
    if (!_validate()) return;

    final email = emailC.text.trim();
    final pass = passC.text;

    setState(() => _loading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user;
      if (user == null) {
        _snack('Registration failed.');
        return;
      }

      // Try to create Firestore document, but proceed even if it fails
      try {
        await _firestore.ensureUserDocument(
          uid: user.uid,
          email: user.email ?? email,
          firstName: firstC.text.trim(),
          lastName: lastC.text.trim(),
        );
      } catch (firestoreError) {
        // Log the error but don't block registration
        // The document will be created on next login or app use
        // ignore: avoid_print
        print('Firestore unavailable during registration: $firestoreError');
        _snack('Account created! Complete your profile on next login.');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } on FirebaseAuthException catch (e) {
      _snack(_authErrorMsg(e));
    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _input(
                            controller: firstC,
                            hint: 'First Name',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _input(
                            controller: lastC,
                            hint: 'Last Name',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _input(
                      controller: emailC,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    _input(
                      controller: passC,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.text,
                      isPassword: true,
                      obscure: _obscure1,
                      onToggleObscure: () =>
                          setState(() => _obscure1 = !_obscure1),
                    ),
                    const SizedBox(height: 12),

                    _input(
                      controller: confirmC,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.text,
                      isPassword: true,
                      obscure: _obscure2,
                      onToggleObscure: () =>
                          setState(() => _obscure2 = !_obscure2),
                      onSubmitted: (_) => _loading ? null : _register(),
                    ),
                    const SizedBox(height: 22),

                    _GradientButton(
                      text: 'Register',
                      loading: _loading,
                      onPressed: _loading ? null : _register,
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: GestureDetector(
                        onTap: _loading
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                        child: RichText(
                          text: const TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: AppColors.text),
                            children: [
                              TextSpan(
                                text: "Login",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? obscure : false,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.subText),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onPressed == null ? 0.995 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Ink(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
