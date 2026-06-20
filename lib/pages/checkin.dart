import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';

class CheckIn extends StatefulWidget {
  const CheckIn({super.key});

  @override
  State<CheckIn> createState() => _CheckInState();
}

class _CheckInState extends State<CheckIn> {
  int? _rispostaRoutine;
  int? _rispostaMood;
  bool _caricamento = false;
  bool _salvato = false;
  bool _giaCompletato = false;
  int _nuovaStreak = 0;
  bool _streakRotta = false;

  final List<Map<String, dynamic>> _opzioniRoutine = [
    {'label': 'Sì',      'icon': Icons.check_circle_rounded,  'color': Color(0xFF66BB6A)},
    {'label': 'In parte','icon': Icons.remove_circle_rounded, 'color': Color(0xFFFFB74D)},
    {'label': 'No',      'icon': Icons.cancel_rounded,        'color': Color(0xFFE57373)},
  ];

  final List<String> _emoji      = ['😞', '😕', '😐', '🙂', '😄'];
  final List<String> _emojiLabel = ['Male', 'Così così', 'Neutro', 'Bene', 'Ottimo'];

  @override
  void initState() {
    super.initState();
    _verificaCheckInOggi();
  }

  String _chiaveData(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

  String _ieri() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _chiaveData(yesterday);
  }

  Future<void> _verificaCheckInOggi() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    final oggi = _chiaveData(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .collection('checkin')
        .doc(oggi)
        .get();

    if (doc.exists && mounted) {
      setState(() => _giaCompletato = true);
    }
  }

  Future<void> _salvaCheckIn() async {
    if (_rispostaRoutine == null || _rispostaMood == null) return;

    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    setState(() => _caricamento = true);

    try {
      final oggi = _chiaveData(DateTime.now());
      final userDoc = FirebaseFirestore.instance.collection('utenti').doc(uid);

      await userDoc.collection('checkin').doc(oggi).set({
        'data'     : oggi,
        'timestamp': FieldValue.serverTimestamp(),
        'routine'  : _rispostaRoutine,
        'mood'     : _rispostaMood,
      });

      final snapshot = await userDoc.get();
      final data = snapshot.data();
      final lastDateStr = data?['lastActiveDate'] as String?;
      final currentStreak = data?['streak'] as int? ?? 0;
      final bestStreak = data?['bestStreak'] as int? ?? 0;

      int nuovaStreak;
      if (lastDateStr == null) {
        nuovaStreak = 1;
      } else if (lastDateStr == oggi) {
        nuovaStreak = currentStreak;
      } else if (lastDateStr == _ieri()) {
        nuovaStreak = currentStreak + 1;
      } else {
        nuovaStreak = 1;
        _streakRotta = lastDateStr.isNotEmpty;
      }

      await userDoc.set({
        'lastActiveDate': oggi,
        'streak': nuovaStreak,
        'bestStreak': nuovaStreak > bestStreak ? nuovaStreak : bestStreak,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _nuovaStreak = nuovaStreak;
          _salvato     = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel salvataggio. Riprova.')),
        );
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Check-in giornaliero',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _salvato
            ? _buildSuccesso()
            : _giaCompletato
            ? _buildGiaCompletato()
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final bool pronto = _rispostaRoutine != null && _rispostaMood != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        Center(
          child: Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EEF7), shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round,
                color: Color(0xFF7A9CC6), size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Come è andata oggi?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w600,
              color: const Color(0xFF3A4A5C),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _dataFormattata(),
            style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
          ),
        ),

        const SizedBox(height: 36),

        Text(
          'Hai seguito la tua routine?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (i) {
            final selezionato = _rispostaRoutine == i;
            final opzione = _opzioniRoutine[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rispostaRoutine = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selezionato
                        ? (opzione['color'] as Color).withValues(alpha: 0.15)
                        : const Color(0xFFE8EEF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selezionato
                          ? opzione['color'] as Color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(opzione['icon'] as IconData,
                          color: selezionato
                              ? opzione['color'] as Color
                              : const Color(0xFF8A9BB5),
                          size: 26),
                      const SizedBox(height: 6),
                      Text(
                        opzione['label'] as String,
                        style: TextStyle(
                          color: selezionato
                              ? opzione['color'] as Color
                              : const Color(0xFF8A9BB5),
                          fontWeight: FontWeight.w600, fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        Text(
          'Come ti sei sentito?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final selezionato = _rispostaMood == i;
            return GestureDetector(
              onTap: () => setState(() => _rispostaMood = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selezionato
                      ? const Color(0xFFD0DCF0)
                      : const Color(0xFFE8EEF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selezionato
                        ? const Color(0xFF7A9CC6)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(_emoji[i], style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      _emojiLabel[i],
                      style: TextStyle(
                        fontSize: 9,
                        color: selezionato
                            ? const Color(0xFF3A4A5C)
                            : const Color(0xFF8A9BB5),
                        fontWeight: selezionato
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const Spacer(),

        GestureDetector(
          onTap: (pronto && !_caricamento) ? _salvaCheckIn : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: pronto
                  ? const Color(0xFF7A9CC6)
                  : const Color(0xFFD0DCF0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _caricamento
                  ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                'Salva check-in',
                style: TextStyle(
                  color: pronto ? Colors.white : const Color(0xFF8A9BB5),
                  fontWeight: FontWeight.w600, fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccesso() {
    final bool primoCheckin = _nuovaStreak == 1 && !_streakRotta;
    final bool streakRotta  = _streakRotta && _nuovaStreak == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9), shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF66BB6A), size: 44),
        ),
        const SizedBox(height: 24),

        Text(
          'Check-in completato!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          streakRotta
              ? 'Ripartito da capo — da oggi si ricomincia! 💪'
              : primoCheckin
              ? 'Ottimo inizio. Il viaggio comincia adesso!'
              : 'Ottimo lavoro. Ci vediamo domani.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A9BB5), fontSize: 14, height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_nuovaStreak ${_nuovaStreak == 1 ? 'giorno' : 'giorni'} di fila',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A4A5C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakRotta ? 'Nuova serie iniziata' : 'Continua così!',
                    style: const TextStyle(
                      color: Color(0xFF8A9BB5), fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
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
                'Torna indietro',
                style: TextStyle(
                  color: Color(0xFF3A4A5C),
                  fontWeight: FontWeight.w600, fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGiaCompletato() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFE8EEF7), shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star_rounded,
              color: Color(0xFF7A9CC6), size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'Già fatto oggi!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hai già completato il check-in per oggi.\nTorna domani!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A9BB5), fontSize: 14, height: 1.6,
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
                'Torna indietro',
                style: TextStyle(
                  color: Color(0xFF3A4A5C),
                  fontWeight: FontWeight.w600, fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  String _dataFormattata() {
    final now = DateTime.now();
    const mesi   = ['gennaio','febbraio','marzo','aprile','maggio','giugno',
      'luglio','agosto','settembre','ottobre','novembre','dicembre'];
    const giorni = ['lunedì','martedì','mercoledì','giovedì','venerdì','sabato','domenica'];
    return '${giorni[now.weekday - 1]} ${now.day} ${mesi[now.month - 1]}';
  }
}
