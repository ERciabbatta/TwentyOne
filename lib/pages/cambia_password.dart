import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Schermata per la modifica della password dell'utente.
/// Consente di richiedere l'invio di una e-mail di reset all'indirizzo associato
/// all'utente attualmente autenticato.
class CambioPassword extends StatefulWidget {
  const CambioPassword({super.key});

  @override
  State<CambioPassword> createState() => _CambioPasswordState();
}

class _CambioPasswordState extends State<CambioPassword> {
  // Indica se l'email di ripristino password è stata inviata con successo
  bool _inviato = false;
  
  // Indica se è in corso la richiesta di rete a Firebase
  bool _caricamento = false;
  
  // Messaggio d'errore restituito da Firebase in caso di problemi
  String? _errore;

  /// Invia l'e-mail di reset della password all'utente corrente
  /// utilizzando il servizio `FirebaseAuth`.
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cambia password',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
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
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset_rounded,
                color: colors.accent, size: 36),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Reimposta la tua password',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ti invieremo un\'email a:\n$email\n\nClicca il link nell\'email per scegliere una nuova password.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 24),

        if (_errore != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.errorBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _errore!,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),

        const Spacer(),

        GestureDetector(
          onTap: _caricamento ? null : _inviaResetEmail,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _caricamento
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: colors.textOnAccent, strokeWidth: 2),
              )
                  : Text(
                'Invia email di reset',
                style: TextStyle(
                  color: colors.textOnAccent,
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
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.successBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_read_outlined,
              color: colors.success, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Email inviata!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Controlla la tua casella (non dimenticare lo spam):\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Torna al profilo',
                style: TextStyle(
                  color: colors.textPrimary,
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

