import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twentyone/pages/calendario.dart';
import 'package:twentyone/pages/completamento.dart';
import 'package:twentyone/pages/checkin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/quotes_data.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Dashboard principale dell'applicazione.
/// Mostra la streak corrente, i giorni rimanenti al completamento del ciclo di 21 giorni,
/// l'obiettivo personale impostato dall'utente, le note del giorno e frasi motivazionali.
class Home extends StatefulWidget {
  Home({super.key});

  final User? user = Auth().currentUser;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Numero consecutivo di giorni con check-in eseguito (streak corrente)
  int _streakCount = 0;
  
  // Giorni ancora necessari a completare il ciclo di 21 giorni
  int _giorniRimanenti = 21;
  
  // true se l'utente ha completato tutti e 21 i giorni
  bool _cicloCompletato = false;
  
  // true se va mostrato il pulsante per effettuare il check-in (dopo le 22:00)
  bool _mostraBottoneCheckin = false;
  
  // Testo dell'obiettivo personale dell'utente
  String _obiettivo = '';

  @override
  void initState() {
    super.initState();
    _caricaDatiUtente();
  }

  /// Recupera in parallelo tutti i dati aggregati per la home
  /// (streak, giorni rimanenti, visibilità pulsante check-in, obiettivo)
  /// e aggiorna lo stato del widget.
  Future<void> _caricaDatiUtente() async {
    final streak    = await _leggiStreak();
    final rimanenti = await _calcolaGiorniRimanenti();
    final mostraBtn = await _calcolaBottoneCheckin();
    final obiettivo = await _caricaObiettivo();
    if (mounted) {
      setState(() {
        _streakCount          = streak;
        _giorniRimanenti      = rimanenti;
        _cicloCompletato      = rimanenti == 0;
        _mostraBottoneCheckin = mostraBtn;
        _obiettivo            = obiettivo;
      });
    }
  }

  /// Recupera il testo dell'obiettivo dell'utente da Firestore.
  Future<String> _caricaObiettivo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .get();
    return doc.data()?['obiettivo'] as String? ?? '';
  }

  /// Determina se mostrare il pulsante del check-in:
  /// lo mostra solo dopo le 22:00 e solo se l'utente non ha già fatto il check-in oggi.
  Future<bool> _calcolaBottoneCheckin() async {
    final ora = DateTime.now().hour;
    if (ora < 22) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .get();

    final lastActiveDate = doc.data()?['lastActiveDate'] as String?;
    final oggi = _dateKey(DateTime.now());
    return lastActiveDate != oggi;
  }

  /// Calcola i giorni rimanenti al completamento del ciclo di 21 giorni
  /// a partire dalla data di inizio salvata su Firestore (o dalla data di creazione account).
  Future<int> _calcolaGiorniRimanenti() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 21;

    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .get();

    final dataInizioStr = doc.data()?['dataInizio'] as String?;

    DateTime dataInizio;
    if (dataInizioStr != null) {
      dataInizio = DateTime.parse(dataInizioStr);
    } else {
      final creazione = user.metadata.creationTime;
      if (creazione == null) return 21;
      dataInizio = DateTime(creazione.year, creazione.month, creazione.day);
      // Salva la data di inizio calcolata per le sessioni future
      await FirebaseFirestore.instance
          .collection('utenti')
          .doc(user.uid)
          .set({
        'dataInizio':
        '${dataInizio.year}-${dataInizio.month.toString().padLeft(2, '0')}-${dataInizio.day.toString().padLeft(2, '0')}'
      }, SetOptions(merge: true));
    }

    final oggi    = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final inizio  = DateTime(dataInizio.year, dataInizio.month, dataInizio.day);
    final passati = oggi.difference(inizio).inDays;
    final rim     = 21 - passati;
    return rim < 0 ? 0 : rim;
  }

  /// Legge il valore corrente della streak dal documento utente su Firestore.
  Future<int> _leggiStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .get();

    final lastDateStr = doc.data()?['lastActiveDate'] as String?;
    final streak = doc.data()?['streak'] as int? ?? 0;

    if (lastDateStr == null) return 0;

    return streak;
  }

  /// Formatta una data come stringa nel formato "YYYY-MM-DD".
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Restituisce l'indice (0 = lunedì … 6 = domenica) del giorno corrente.
  int get _giornoOggi => DateTime.now().weekday - 1;

  /// Stream che emette gli aggiornamenti in tempo reale delle note dell'utente da Firestore.
  Stream<QuerySnapshot> _noteStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('utenti')
        .doc(user!.uid)
        .collection('note')
        .snapshots();
  }

  /// Estrae l'ora intera da una stringa di orario in formato "HH:MM".
  int _getOra(String orario) {
    try {
      return int.parse(orario.split(':')[0]);
    } catch (_) {
      return 0;
    }
  }

  /// Restituisce la fascia oraria ("mattina", "pomeriggio", "sera")
  /// in base all'ora di inizio dell'evento o dell'attività.
  String _getFasciaOraria(String inizio) {
    final ora = _getOra(inizio);
    if (ora >= 6 && ora < 12) return 'mattina';
    if (ora >= 12 && ora < 18) return 'pomeriggio';
    return 'sera';
  }

  Widget _buildObiettivoCard(IconData icon, String label, String valore, String sublabel) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceSelected,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.accent, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valore,
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildObiettivoStrip() {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: colors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _obiettivo,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaRow(Map<String, dynamic> nota) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('• ', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          Text(nota['inizio'] ?? '',
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(nota['testo'] ?? '',
                style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ),
          Text(nota['fine'] ?? '',
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFasciaOraria(IconData icon, String titolo,
      List<Map<String, dynamic>> note, bool showDivider) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titolo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    if (note.isEmpty)
                      Text('Nessuna nota',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13))
                    else
                      ...note.map((nota) => _buildNotaRow(nota)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: colors.cardBorder, thickness: 1),
      ],
    );
  }

  Widget _buildBannerCompletamento() {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Completamento()),
        ).then((_) => _caricaDatiUtente());
      },
      child: Container(
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
          children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hai completato i 21 giorni!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tocca per vedere il riepilogo',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCheckin() {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckIn()),
        ).then((_) => _caricaDatiUtente());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceSelected,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.nightlight_round,
                  color: colors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in serale',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Come è andata oggi?',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: colors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteOfDay = getQuoteOfDay();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Calendario()),
              );
            },
            icon: Icon(Icons.calendar_month_outlined,
                color: colors.textPrimary),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _noteStream(),
        builder: (context, snapshot) {
          final mattina    = <Map<String, dynamic>>[];
          final pomeriggio = <Map<String, dynamic>>[];
          final sera       = <Map<String, dynamic>>[];

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final nota   = doc.data() as Map<String, dynamic>;
              final giorni = List<int>.from(nota['giorni'] ?? []);
              if (!giorni.contains(_giornoOggi)) continue;
              final fascia = _getFasciaOraria(nota['inizio'] ?? '');
              if (fascia == 'mattina'){
                mattina.add(nota);
              }
              else if (fascia == 'pomeriggio') {
                pomeriggio.add(nota);
              }
              else {
                sera.add(nota);
              }
            }

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
                if (_cicloCompletato) ...[
                  _buildBannerCompletamento(),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    _buildObiettivoCard(
                      Icons.local_fire_department_outlined,
                      'Streak', '$_streakCount', 'GIORNI',
                    ),
                    const SizedBox(width: 12),
                    _buildObiettivoCard(
                      Icons.star_border,
                      'Obiettivo 21 giorni', '$_giorniRimanenti', 'GIORNI RIMANENTI',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_obiettivo.isNotEmpty) ...[
                  _buildObiettivoStrip(),
                  const SizedBox(height: 12),
                ],

                if (_mostraBottoneCheckin) ...[
                  _buildBannerCheckin(),
                  const SizedBox(height: 12),
                ],

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\u201C',
                        style: TextStyle(
                            fontSize: 36, color: colors.accent, height: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quoteOfDay.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
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
                    children: [
                      _buildFasciaOraria(
                          Icons.wb_sunny_outlined, 'Mattina', mattina, true),
                      _buildFasciaOraria(
                          Icons.wb_twilight_outlined, 'Pomeriggio', pomeriggio, true),
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
