import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';

class Completamento extends StatefulWidget {
  const Completamento({super.key});

  @override
  State<Completamento> createState() => _CompletamentoState();
}

class _CompletamentoState extends State<Completamento> {
  bool _caricamento = true;
  int _giorniCompletati = 0;
  double _moodMedio = 0;
  int _streakMassima = 0;

  @override
  void initState() {
    super.initState();
    _caricaStatistiche();
  }

  Future<void> _caricaStatistiche() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) {
      setState(() => _caricamento = false);
      return;
    }

    try {
      final checkinSnap = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .collection('checkin')
          .get();

      final checkins = checkinSnap.docs;
      final giorni = checkins.length;

      double moodTotale = 0;
      for (final doc in checkins) {
        final mood = doc.data()['mood'] as int? ?? 2;
        moodTotale += mood;
      }
      final moodMedio = giorni > 0 ? moodTotale / giorni : 0.0;

      final utenteSnap = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .get();
      final streak = utenteSnap.data()?['streak'] as int? ?? 0;

      setState(() {
        _giorniCompletati = giorni;
        _moodMedio = moodMedio;
        _streakMassima = streak;
        _caricamento = false;
      });
    } catch (_) {
      setState(() => _caricamento = false);
    }
  }

  Future<void> _iniziaNuovoCiclo() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    final oggi = DateTime.now();
    final oggiStr =
        '${oggi.year}-${oggi.month.toString().padLeft(2, '0')}-${oggi.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('utenti').doc(uid).set(
      {'dataInizio': oggiStr, 'streak': 0, 'lastActiveDate': null},
      SetOptions(merge: true),
    );

    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _moodLabel(double media) {
    if (media < 1) return 'Difficile';
    if (media < 2) return 'Così così';
    if (media < 3) return 'Neutro';
    if (media < 4) return 'Bene';
    return 'Ottimo';
  }

  String _moodEmoji(double media) {
    if (media < 1) return '😞';
    if (media < 2) return '😕';
    if (media < 3) return '😐';
    if (media < 4) return '🙂';
    return '😄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _caricamento
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF7A9CC6)),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFB74D), size: 54),
              ),
              const SizedBox(height: 28),
              Text(
                'Hai completato\ni 21 giorni!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A4A5C),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hai costruito una nuova abitudine.\nEcco il riepilogo del tuo ciclo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A9BB5),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildStatCard(
                    Icons.calendar_today_rounded,
                    '$_giorniCompletati',
                    'Check-in fatti',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    Icons.local_fire_department_rounded,
                    '$_streakMassima',
                    'Streak attuale',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _moodEmoji(_moodMedio),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood medio',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: Color(0xFF8A9BB5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moodLabel(_moodMedio),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A4A5C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _iniziaNuovoCiclo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A9CC6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Inizia un nuovo ciclo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      'Continua a usare l\'app',
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String valore, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFD0DCF0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF7A9CC6), size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              valore,
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3A4A5C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A9BB5)),
            ),
          ],
        ),
      ),
    );
  }
}
