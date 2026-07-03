import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';
import 'dart:math';

/// Schermata visualizzata al completamento del percorso dei 21 giorni.
/// Presenta statistiche riassuntive sull'andamento delle routine e del mood,
/// ed esegue un'animazione festosa con coriandoli colorati.
class Completamento extends StatefulWidget {
  const Completamento({super.key});

  @override
  State<Completamento> createState() => _CompletamentoState();
}

class _CompletamentoState extends State<Completamento>
    with TickerProviderStateMixin {
  // Controller di animazione per il ridimensionamento degli elementi grafici centrali
  late AnimationController _scaleController;
  
  // Controller di animazione per l'effetto di dissolvenza (fade-in) dei testi
  late AnimationController _fadeController;
  
  // Controller di animazione che gestisce la caduta continua dei coriandoli
  late AnimationController _confettiController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Lista delle particelle (coriandoli) animate a schermo
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  // Flag che indica se il caricamento delle statistiche da Firestore è in corso
  bool _loading = true;
  
  // Valore medio del mood dell'utente durante il percorso
  double _moodMedio = 0;
  
  // Percentuale di completamento positivo delle routine giornaliere
  double _routinePercent = 0;
  
  // Valore massimo di mood registrato
  int _giornoMigliore = 0;
  
  // Numero totale di check-in effettuati
  int _checkInTotali = 0;

  final List<String> _emoji = ['😞', '😕', '😐', '🙂', '😄'];
  final List<String> _emojiLabel = ['Male', 'Così così', 'Neutro', 'Bene', 'Ottimo'];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(random: _random));
    }

    _caricaStatistiche();
  }

  /// Recupera la cronologia dei check-in dell'utente da Firestore e calcola le statistiche di riassunto.
  Future<void> _caricaStatistiche() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .collection('checkin')
        .get();

    final docs = snapshot.docs;

    if (docs.isEmpty) {
      setState(() => _loading = false);
      _avviaAnimazioni();
      return;
    }

    int totaleMood = 0;
    int routineSi = 0;
    int moodMax = 0;

    for (final doc in docs) {
      final data = doc.data();
      final mood = data['mood'] as int? ?? 0;
      final routine = data['routine'] as int? ?? 2;

      totaleMood += mood;
      if (routine == 0) routineSi++;
      if (mood > moodMax) moodMax = mood;
    }

    setState(() {
      _checkInTotali = docs.length;
      _moodMedio = totaleMood / docs.length;
      _routinePercent = (routineSi / docs.length) * 100;
      _giornoMigliore = moodMax;
      _loading = false;
    });

    _avviaAnimazioni();
  }

  /// Avvia i vari controller di animazione con un piccolo ritardo per fluidità visiva.
  void _avviaAnimazioni() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _scaleController.forward();
      _fadeController.forward();
      _confettiController.repeat();
    });
  }

  /// Mostra una finestra di dialogo di conferma per ripristinare il percorso di 21 giorni
  /// eliminando i dati correnti su Firestore (check-in, note, obiettivo).
  Future<void> _mostraDialogReset() async {
    final colors = AppColors.of(context);
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ricominciare il percorso?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tutti i progressi, i check-in e lo streak verranno azzerati. Sei sicuro?',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Annulla',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.errorBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Reimposta',
                            style: TextStyle(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (conferma != true) return;

    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    final utentiRef = FirebaseFirestore.instance.collection('utenti').doc(uid);

    // bestStreak NON viene toccato: è il record storico personale.
    // Le note non vengono toccate: sono ricorrenti settimanali, non legate

    await utentiRef.set({
      'dataInizio': DateTime.now().toIso8601String().substring(0, 10),
      'streak': 0,
      'lastActiveDate': null,
    }, SetOptions(merge: true));

    final checkin = await utentiRef.collection('checkin').get();
    for (final doc in checkin.docs) {
      await doc.reference.delete();
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String get _moodEmoji => _emoji[_moodMedio.round().clamp(0, 4)];
  String get _moodLabel => _emojiLabel[_moodMedio.round().clamp(0, 4)];

  Widget _buildStatCard(String titolo, String valore, String sottotitolo, {Widget? custom}) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              titolo,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            custom ?? Text(
              valore,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sottotitolo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          if (_loading)
            Center(child: CircularProgressIndicator(color: colors.accent))
          else
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 52,
                            color: colors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Ce l\'hai fatta!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hai completato il tuo percorso di 21 giorni.\nHai costruito qualcosa di straordinario.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.accent, colors.accentGradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '21',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: colors.textOnAccent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'giorni',
                                  style: TextStyle(
                                    color: colors.textOnAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'di costanza',
                                  style: TextStyle(
                                    color: colors.textOnAccent.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_checkInTotali > 0) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'I tuoi 21 giorni in numeri',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildStatCard(
                              'MOOD MEDIO',
                              '',
                              _moodLabel,
                              custom: Text(
                                _moodEmoji,
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'ROUTINE SEGUITA',
                              '${_routinePercent.round()}%',
                              'dei giorni',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard(
                              'CHECK-IN TOTALI',
                              '$_checkInTotali',
                              'su 21 giorni',
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'GIORNO MIGLIORE',
                              '',
                              _emojiLabel[_giornoMigliore.clamp(0, 4)],
                              custom: Text(
                                _emoji[_giornoMigliore.clamp(0, 4)],
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: colors.accentGradientEnd,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Continua',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              color: colors.textOnAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _mostraDialogReset,
                          style: TextButton.styleFrom(
                            backgroundColor: colors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Ricomincia il percorso',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              color: colors.textSecondary,
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
            ),
        ],
      ),
    );
  }
}

/// Modella una singola particella di coriandolo per l'effetto festivo.
/// Contiene coordinate, dimensioni, velocità di caduta e caratteristiche di rotazione.
class _ConfettiParticle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double wobble;
  late Color color;
  late double rotation;

  _ConfettiParticle({required Random random}) {
    x = random.nextDouble();
    y = random.nextDouble() * -1;
    size = random.nextDouble() * 8 + 4;
    speed = random.nextDouble() * 0.3 + 0.1;
    wobble = random.nextDouble() * 0.05;
    rotation = random.nextDouble() * 2 * pi;
    const colors = [
      Color(0xFF4A7BA7),
      Color(0xFFE8EEF7),
      Color(0xFF2C3E50),
      Color(0xFF85C1E9),
      Color(0xFFF8C471),
      Color(0xFF82E0AA),
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

/// CustomPainter per disegnare le particelle di coriandoli a schermo.
/// Gestisce la traslazione, oscillazione (wobble) e la rotazione di ogni singola particella.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: 0.8);
      final x = (p.x + sin(progress * 2 * pi * p.wobble * 10)) * size.width;
      final y = (p.y + progress * p.speed * 3) % 1.2 * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
