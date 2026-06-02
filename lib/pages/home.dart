import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/calendario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/widget/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/widget/quotes_data.dart';

class Home extends StatefulWidget {
  Home({super.key});

  final User? user = Auth().currentUser;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    checkAndUpdateStreak().then((val) {
      if (mounted) setState(() => _streakCount = val);
    });
  }

  Future<int> checkAndUpdateStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final doc = FirebaseFirestore.instance.collection('utenti').doc(user.uid);
    final snapshot = await doc.get();
    final data = snapshot.data();

    final today = DateTime.now();
    final todayStr = _dateKey(today);
    final lastDateStr = data?['lastActiveDate'] as String?;
    final currentStreak = data?['streak'] as int? ?? 0;

    if (lastDateStr == null) {
      await doc.set({'lastActiveDate': todayStr, 'streak': 1}, SetOptions(merge: true));
      return 1;
    }

    final lastDate = DateTime.parse(lastDateStr);
    final diff = _dayDifference(lastDate, today);

    if (diff == 0) return currentStreak;

    final newStreak = diff == 1 ? currentStreak + 1 : 1;
    await doc.set({'lastActiveDate': todayStr, 'streak': newStreak}, SetOptions(merge: true));
    return newStreak;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _dayDifference(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  // DateTime.weekday: 1=Lun, 2=Mar, ..., 7=Dom
  // Array giorni in Firestore: 0=Lun, 1=Mar, ..., 6=Dom
  int get _giornoOggi => DateTime.now().weekday - 1;

  Stream<QuerySnapshot> _noteStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('utenti')
        .doc(user!.uid)
        .collection('note')
        .snapshots();
  }

  int _getOra(String orario) {
    try {
      return int.parse(orario.split(':')[0]);
    } catch (_) {
      return 0;
    }
  }

  String _getFasciaOraria(String inizio) {
    final ora = _getOra(inizio);
    if (ora >= 6 && ora < 12) return 'mattina';
    if (ora >= 12 && ora < 18) return 'pomeriggio';
    return 'sera';
  }

  Widget _buildObiettivoCard(IconData icon, String label, String valore, String sublabel) {
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
              sublabel,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Color(0xFF8A9BB5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A9BB5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotaRow(Map<String, dynamic> nota) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 16)),
          Text(
            nota['inizio'] ?? '',
            style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nota['testo'] ?? '',
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
            ),
          ),
          Text(
            nota['fine'] ?? '',
            style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFasciaOraria(IconData icon, String titolo,
      List<Map<String, dynamic>> note, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF7A9CC6), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titolo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3A4A5C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (note.isEmpty)
                      const Text(
                        'Nessuna nota',
                        style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
                      )
                    else
                      ...note.map((nota) => _buildNotaRow(nota)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(color: Color(0xFFE2E8F0), thickness: 1),
      ],
    );
  }

  int _giorniAlTraguardo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 21;
    final creazione = user.metadata.creationTime;
    if (creazione == null) return 21;
    final oggi = DateTime.now();
    final giornoCreazione =
    DateTime(creazione.year, creazione.month, creazione.day);
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final passati = oggiPulito.difference(giornoCreazione).inDays;
    final rimanenti = 21 - passati;
    return rimanenti < 0 ? 0 : rimanenti;
  }

  @override
  Widget build(BuildContext context) {
    final quoteOfDay = getQuoteOfDay();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Calendario()),
              );
            },
            icon: const Icon(Icons.calendar_month_outlined,
                color: Color(0xFF3A4A5C)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _noteStream(),
        builder: (context, snapshot) {
          final mattina = <Map<String, dynamic>>[];
          final pomeriggio = <Map<String, dynamic>>[];
          final sera = <Map<String, dynamic>>[];

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final nota = doc.data() as Map<String, dynamic>;

              // Mostra solo le note del giorno della settimana corrente
              final giorni = List<int>.from(nota['giorni'] ?? []);
              if (!giorni.contains(_giornoOggi)) continue;

              final fascia = _getFasciaOraria(nota['inizio'] ?? '');
              if (fascia == 'mattina') mattina.add(nota);
              else if (fascia == 'pomeriggio') pomeriggio.add(nota);
              else sera.add(nota);
            }

            // Ordina ciascuna fascia per orario di inizio
            for (final lista in [mattina, pomeriggio, sera]) {
              lista.sort((a, b) {
                final aMin = _getOra(a['inizio'] ?? '00:00') * 60 +
                    (int.tryParse((a['inizio'] ?? '00:00').split(':')[1]) ?? 0);
                final bMin = _getOra(b['inizio'] ?? '00:00') * 60 +
                    (int.tryParse((b['inizio'] ?? '00:00').split(':')[1]) ?? 0);
                return aMin.compareTo(bMin);
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildObiettivoCard(
                      Icons.local_fire_department_outlined,
                      'Streak',
                      '$_streakCount',
                      'GIORNI',
                    ),
                    const SizedBox(width: 12),
                    _buildObiettivoCard(
                      Icons.star_border,
                      'Obiettivo 21 giorni',
                      '${_giorniAlTraguardo()}',
                      'GIORNI RIMANENTI',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '\u201C',
                        style: TextStyle(
                          fontSize: 36,
                          color: Color(0xFF7A9CC6),
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quoteOfDay.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFasciaOraria(
                          Icons.wb_sunny_outlined, 'Mattina', mattina, true),
                      _buildFasciaOraria(Icons.wb_twilight_outlined,
                          'Pomeriggio', pomeriggio, true),
                      _buildFasciaOraria(
                          Icons.nightlight_outlined, 'Sera', sera, false),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}