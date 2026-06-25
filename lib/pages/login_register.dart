import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';

class LoginRegister extends StatefulWidget {
  final bool startAsLogin;
  const LoginRegister({super.key, this.startAsLogin = true});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  late bool isLogin;
  String? errorMessage = '';

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLogin = widget.startAsLogin;
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_controllerName.text.trim());
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colors.accent, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                isLogin ? 'Bentornato.' : 'Crea account.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin ? 'Accedi per continuare' : 'Registrati per iniziare',
                style: TextStyle(color: colors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 40),
              if (!isLogin) ...[
                _inputField(
                  label: 'Nome',
                  icon: Icons.person_outline_rounded,
                  controller: _controllerName,
                ),
                const SizedBox(height: 12),
              ],
              _inputField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _controllerEmail,
              ),
              const SizedBox(height: 12),
              _inputField(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _controllerPassword,
                obscure: true,
              ),
              if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.errorBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: colors.error, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: isLogin
                    ? signInWithEmailAndPassword
                    : createUserWithEmailAndPassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLogin ? 'Accedi' : 'Registrati',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textOnAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isLogin = !isLogin;
                      errorMessage = '';
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Non hai un account? Registrati'
                        : 'Hai già un account? Accedi',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}