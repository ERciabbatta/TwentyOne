import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/calendario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  Home({super.key});

  final User? user = Auth().currentUser;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  int _streakCount = 0;

  static const _keyStreak = 'streak_count';
  static const _keyLastDate = 'last_active_date';

  @override
  void initState() {
    super.initState();
    checkAndUpdateStreak().then((val) {
      if (mounted) setState(() => _streakCount = val);
    });
  }

  Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = _dateKey(today);

    final lastDateStr = prefs.getString(_keyLastDate);
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;

    if (lastDateStr == null) {
      await prefs.setString(_keyLastDate, todayStr);
      await prefs.setInt(_keyStreak, 1);
      return 1;
    }

    final lastDate = DateTime.parse(lastDateStr);
    final diff = _dayDifference(lastDate, today);

    int newStreak;

    if (diff == 0) {
      return currentStreak;
    } else if (diff == 1) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    await prefs.setString(_keyLastDate, todayStr);
    await prefs.setInt(_keyStreak, newStreak);
    return newStreak;
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _dayDifference(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  final List<String> _frasi = [
    "Ogni giorno è una nuova opportunità per migliorare.",
    "Il successo è la somma di piccoli sforzi ripetuti ogni giorno.",
    "Non aspettare il momento giusto, crealo tu.",
    "La disciplina è il ponte tra gli obiettivi e i risultati.",
    "Credi in te stesso e il mondo crederà in te.",
    "Il viaggio di mille miglia inizia con un singolo passo.",
    "Non è mai troppo tardi per diventare ciò che avresti potuto essere.",
    "La forza non viene dall'abilità fisica, ma dalla volontà indomita.",
    "Ogni mattina hai due scelte: continuare a dormire o alzarti e inseguire i tuoi sogni.",
    "Il fallimento è solo l'opportunità di ricominciare in modo più intelligente.",
    "Non contare i giorni, fai sì che i giorni contino.",
    "La vita inizia dove finisce la tua zona di comfort.",
    "Sii il cambiamento che vuoi vedere nel mondo.",
    "Il coraggio non è l'assenza di paura, ma agire nonostante essa.",
    "Ogni esperto è stato una volta un principiante.",
    "Il tuo unico limite sei tu.",
    "Sogna in grande, lavora sodo, rimani umile.",
    "Non smettere mai quando sei stanco, smetti quando hai finito.",
    "Il presente è il momento in cui costruisci il tuo futuro.",
    "Piccoli passi ogni giorno portano a grandi risultati.",
    "La motivazione ti fa iniziare, l'abitudine ti fa continuare.",
    "Sii più forte delle tue scuse.",
    "Il dolore di oggi è la forza di domani.",
    "Non confrontarti con gli altri, confrontati con chi eri ieri.",
    "Le grandi cose non vengono dalla zona di comfort.",
    "Ogni giorno fai qualcosa che ti avvicini al tuo obiettivo.",
    "Il successo non è definitivo, il fallimento non è fatale.",
    "Investi in te stesso, è il miglior investimento che puoi fare.",
    "La perseveranza è la chiave che apre tutte le porte.",
    "Oggi è sempre il giorno migliore per iniziare.",
  ];

  String _getFraseDelGiorno() {
    final giorno = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return _frasi[giorno % _frasi.length];
  }

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

  Widget _buildFasciaOraria(IconData icon, String titolo, List<Map<String, dynamic>> note, bool showDivider) {
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
        if (showDivider)
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
      ],
    );
  }

  int _giorniAlTraguardo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 21;
    final creazione = user.metadata.creationTime;
    if (creazione == null) return 21;
    final oggi = DateTime.now();
    final giornoCreazione = DateTime(creazione.year, creazione.month, creazione.day);
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final passati = oggiPulito.difference(giornoCreazione).inDays;
    final rimanenti = 21 - passati;
    return rimanenti < 0 ? 0 : rimanenti;
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF3A4A5C)),
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
              final fascia = _getFasciaOraria(nota['inizio'] ?? '');
              if (fascia == 'mattina') mattina.add(nota);
              else if (fascia == 'pomeriggio') pomeriggio.add(nota);
              else sera.add(nota);
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
                        _getFraseDelGiorno(),
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
                      _buildFasciaOraria(Icons.wb_sunny_outlined, 'Mattina', mattina, true),
                      _buildFasciaOraria(Icons.wb_twilight_outlined, 'Pomeriggio', pomeriggio, true),
                      _buildFasciaOraria(Icons.nightlight_outlined, 'Sera', sera, false),
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