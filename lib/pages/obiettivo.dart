import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Schermata di onboarding per definire l'obiettivo personale del ciclo di 21 giorni.
/// Può essere usata sia come schermata di primo avvio che come schermata di modifica
/// dell'obiettivo esistente (quando [modifica] è `true`).
class OnboardingObiettivo extends StatefulWidget {
  /// Se true, la schermata opera in modalità modifica (pre-popola il campo con l'obiettivo salvato).
  final bool modifica;

  /// Callback invocata al completamento dell'onboarding (non in modalità modifica).
  final VoidCallback? onCompletato;
  const OnboardingObiettivo({super.key, this.modifica = false, this.onCompletato});

  @override
  State<OnboardingObiettivo> createState() => _OnboardingObiettivoState();
}

class _OnboardingObiettivoState extends State<OnboardingObiettivo> {
  // Controller per il campo di testo in cui l'utente scrive l'obiettivo
  final _controller = TextEditingController();
  
  // true durante il salvataggio su Firestore
  bool _caricamento = false;
  
  // Messaggio di errore di validazione
  String? _errore;

  // Lista di suggerimenti di obiettivi da mostrare come chip selezionabili
  final List<String> _suggerimenti = [
    'Meditare ogni mattina',
    'Correre 3 volte a settimana',
    'Leggere 20 minuti al giorno',
    'Smettere di fumare',
    'Mangiare sano',
    'Studiare una nuova lingua',
    'Dormire prima di mezzanotte',
    'Fare stretching ogni sera',
  ];

  @override
  void initState() {
    super.initState();
    // In modalità modifica, pre-popola il campo con l'obiettivo già salvato
    if (widget.modifica) _caricaObiettivoEsistente();
  }

  /// Recupera l'obiettivo corrente salvato su Firestore e lo inserisce nel controller.
  Future<void> _caricaObiettivoEsistente() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .get();
    final obiettivo = doc.data()?['obiettivo'] as String?;
    if (obiettivo != null && mounted) {
      _controller.text = obiettivo;
    }
  }

  /// Valida il testo inserito e salva l'obiettivo su Firestore.
  /// In modalità modifica effettua un `pop` con il valore aggiornato,
  /// altrimenti invoca la callback [onCompletato].
  Future<void> _salva() async {
    final testo = _controller.text.trim();
    if (testo.isEmpty) {
      setState(() => _errore = 'Scrivi il tuo obiettivo per continuare.');
      return;
    }
    if (testo.length > 80) {
      setState(() => _errore = 'Massimo 80 caratteri.');
      return;
    }

    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _caricamento = true;
      _errore = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .set({'obiettivo': testo}, SetOptions(merge: true));

      if (!mounted) return;
      if (widget.modifica) {
        Navigator.pop(context, testo);
      } else {
        widget.onCompletato?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _errore = 'Errore nel salvataggio. Riprova.');
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,

      appBar: widget.modifica
          ? AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Il mio obiettivo',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: widget.modifica ? 24 : 60),

              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_rounded,
                      color: colors.accent, size: 36),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  widget.modifica
                      ? 'Modifica il tuo obiettivo'
                      : 'Cosa vuoi costruire\nin 21 giorni?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  widget.modifica
                      ? 'Puoi cambiarlo quando vuoi.'
                      : 'Scegli un\'abitudine concreta e tienila\ncostante per 21 giorni.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _controller,
                maxLength: 80,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Es. Meditare ogni mattina',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  counterStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: colors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (_) {
                  if (_errore != null) setState(() => _errore = null);
                },
              ),

              if (_errore != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errore!,
                  style: TextStyle(
                      color: colors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 16),

              Text(
                'Oppure scegli uno di questi:',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggerimenti.map((s) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = s;
                      if (_errore != null) setState(() => _errore = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: colors.surfaceSelected, width: 1),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _caricamento ? null : _salva,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                          color: colors.textOnAccent, strokeWidth: 2
                      ),
                    )
                        : Text(
                      widget.modifica ? 'Salva' : 'Inizia i 21 giorni →',
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
          ),
        ),
      ),
    );
  }
}
