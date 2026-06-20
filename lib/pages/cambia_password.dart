import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/auth.dart';

class CambioPassword extends StatefulWidget {
  const CambioPassword({super.key});

  @override
  State<CambioPassword> createState() => _CambioPasswordState();
}

class _CambioPasswordState extends State<CambioPassword> {
  bool _inviato = false;
  bool _caricamento = false;
  String? _errore;

  Future<void> _inviaResetEmail() async {
    final email = Auth().currentUser?.email;
    if (email == null) return;

    setState(() {
      _caricamento = true;
      _errore = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _inviato = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _errore = e.message);
    } finally {
      setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Auth().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF3A4A5C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cambia password',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _inviato ? _buildSuccesso(email) : _buildForm(email),
      ),
    );
  }

  Widget _buildForm(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: Color(0xFF7A9CC6), size: 36),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Reimposta la tua password',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ti invieremo un\'email a:\n$email\n\nClicca il link nell\'email per scegliere una nuova password.',
          style: const TextStyle(
            color: Color(0xFF8A9BB5),
            fontSize: 14,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 24),

        if (_errore != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _errore!,
              style: const TextStyle(color: Color(0xFFE57373), fontSize: 13),
            ),
          ),

        const Spacer(),

        GestureDetector(
          onTap: _caricamento ? null : _inviaResetEmail,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF7A9CC6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _caricamento
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text(
                'Invia email di reset',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccesso(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFF66BB6A), size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Email inviata!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Controlla la tua casella (non dimenticare lo spam):\n$email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A9BB5),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Torna al profilo',
                style: TextStyle(
                  color: Color(0xFF3A4A5C),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

