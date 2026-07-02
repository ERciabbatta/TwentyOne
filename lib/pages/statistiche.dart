import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Schermata delle statistiche personali del ciclo di 21 giorni.
/// Mostra grafici sull'andamento del mood e delle routine giornaliere,
/// oltre a card riepilogative su streak, best streak, check-in totali e media mood.
class Statistiche extends StatefulWidget {
  const Statistiche({super.key});

  @override
  State<Statistiche> createState() => _StatisticheState();
}

class _StatisticheState extends State<Statistiche> {
  bool _caricamento = true;

  // Carico i giorni dal startDate del ciclo fino ad oggi.
  // Saranno al massimo 21, ma crescono ogni giorno man mano che il ciclo avanza.
  // Così il grafico non ha buchi futuri e riflette esattamente i giorni vissuti.
  final List<_GiornoStats> _giorni = [];

  // Aggregati mostrati nelle card in cima
  int _streak = 0;
  int _bestStreak = 0;
  int _totaleCheckin = 0;
  double _mediaMood = 0;
  int _routineCompletate = 0;

  // Numero di giorni caricati (da 1 a 21): usato per il titolo del grafico mood
  int _giornoCiclo = 0;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    final uid = Auth().currentUser?.uid;
    debugPrint('>>> uid: $uid');
    if (uid == null) return;

    final userDoc = FirebaseFirestore.instance.collection('utenti').doc(uid);

    // Leggo streak, bestStreak e startDate dal documento utente principale
    final userSnap = await userDoc.get();
    final userData = userSnap.data();
    debugPrint('>>> userData: $userData');

    _streak     = userData?['streak']     as int? ?? 0;
    _bestStreak = userData?['bestStreak'] as int? ?? 0;

    // Il campo si chiama dataInizio ed è una stringa "YYYY-MM-DD"
    final dataInizioStr = userData?['dataInizio'] as String?;
    debugPrint('>>> dataInizioStr: $dataInizioStr');

    final oggi = DateTime.now();

    // Parso la stringa; se manca uso oggi come fallback
    DateTime startDate;
    if (dataInizioStr != null) {
      final parts = dataInizioStr.split('-');
      startDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      startDate = DateTime(oggi.year, oggi.month, oggi.day);
    }

    // Calcolo quanti giorni sono passati dallo startDate (oggi incluso).
    // Non supero mai 21 anche se per qualche motivo startDate fosse molto vecchio.
    final giorniTrascorsi = oggi.difference(startDate).inDays + 1;
    final totGiorni       = giorniTrascorsi.clamp(1, 21);
    debugPrint('>>> startDate: $startDate | giorniTrascorsi: $giorniTrascorsi | totGiorni: $totGiorni');

    // Genero le chiavi da startDate fino ad oggi — niente giorni futuri
    final chiavi = List.generate(totGiorni, (i) {
      final d = startDate.add(Duration(days: i));
      return _chiaveData(d);
    });
    debugPrint('>>> chiavi: $chiavi');

    // Lancio tutte le letture in parallelo con Future.wait per velocizzare
    final futures = chiavi
        .map((key) => userDoc.collection('checkin').doc(key).get())
        .toList();
    final docs = await Future.wait(futures);

    int sumMood   = 0;
    int countMood = 0;

    for (int i = 0; i < chiavi.length; i++) {
      final doc = docs[i];
      debugPrint('>>> checkin ${chiavi[i]}: exists=${doc.exists} data=${doc.data()}');
      if (doc.exists) {
        final data    = doc.data()!;
        final mood    = data['mood']    as int?;
        final routine = data['routine'] as int?;

        _totaleCheckin++;
        if (mood != null) {
          sumMood += mood;
          countMood++;
        }
        // routine == 0 significa "completata al 100%"
        if (routine == 0) _routineCompletate++;

        _giorni.add(_GiornoStats(
          data: chiavi[i],
          mood: mood,
          routine: routine,
          completato: true,
        ));
      } else {
        // Il documento non esiste: giorno saltato
        _giorni.add(_GiornoStats(
          data: chiavi[i],
          mood: null,
          routine: null,
          completato: false,
        ));
      }
    }

    _mediaMood   = countMood > 0 ? sumMood / countMood : 0;
    _giornoCiclo = totGiorni;
    debugPrint('>>> _giorni.length: ${_giorni.length} | _giornoCiclo: $_giornoCiclo | _mediaMood: $_mediaMood');

    if (mounted) setState(() => _caricamento = false);
  }

  // Formato chiave Firestore: YYYY-MM-DD
  String _chiaveData(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Slice degli ultimi 7 giorni — usato dal grafico routine.
  // Se il ciclo è ancora giovane e ha meno di 7 giorni, prendo tutto.
  List<_GiornoStats> get _giorni7 =>
      _giorni.length > 7 ? _giorni.sublist(_giorni.length - 7) : List.of(_giorni);

  // Slice degli ultimi 14 giorni — usato dal calendario.
  List<_GiornoStats> get _giorni14 =>
      _giorni.length > 14 ? _giorni.sublist(_giorni.length - 14) : List.of(_giorni);

  @override
  Widget build(BuildContext context) {
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
          'Statistiche',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _caricamento
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildRiepilogoCards(colors),
            const SizedBox(height: 32),
            // Mood: mostro i giorni dall'inizio del ciclo fino ad oggi
            _buildSectionTitle('Umore — giorno 1 › $_giornoCiclo', colors),
            const SizedBox(height: 14),
            _buildMoodChart(colors),
            const SizedBox(height: 32),
            // Routine su 7 giorni: visione settimanale più leggibile
            _buildSectionTitle('Routine — ultimi 7 giorni', colors),
            const SizedBox(height: 14),
            _buildRoutineChart(colors),
            const SizedBox(height: 32),
            _buildSectionTitle('Calendario check-in', colors),
            const SizedBox(height: 14),
            _buildCalendarioStreak(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Le 4 card in cima con i numeri principali
  Widget _buildRiepilogoCards(AppColors colors) {
    final emojiMood = _emojiPerMood(_mediaMood);
    // Percentuale di giorni con routine completata rispetto ai check-in totali
    final pct = _totaleCheckin > 0
        ? (_routineCompletate / _totaleCheckin * 100).round()
        : 0;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(label: 'Streak attuale', value: '$_streak 🔥',     colors: colors),
        _StatCard(label: 'Record streak',  value: '$_bestStreak 🏆', colors: colors),
        _StatCard(label: 'Umore medio',    value: emojiMood,          colors: colors),
        _StatCard(label: 'Routine ok',     value: '$pct%',            colors: colors),
      ],
    );
  }

  // Converto la media numerica (0–4) in un emoji rappresentativo
  String _emojiPerMood(double v) {
    if (v < 1) return '😞';
    if (v < 2) return '😕';
    if (v < 3) return '😐';
    if (v < 4) return '🙂';
    return '😄';
  }

  // ── Grafico umore: LineChart dall'inizio del ciclo fino ad oggi ──────────
  Widget _buildMoodChart(AppColors colors) {
    // Creo i punti del grafico: salto i giorni senza check-in
    final spots = <FlSpot>[];
    for (int i = 0; i < _giorni.length; i++) {
      final g = _giorni[i];
      if (g.completato && g.mood != null) {
        spots.add(FlSpot(i.toDouble(), g.mood!.toDouble()));
      }
    }
    if (spots.isEmpty) return _emptyState('Nessun dato ancora', colors);

    // Su pochi giorni mostro ogni giorno, su tanti ogni 7
    final intervalloX = _giorni.length <= 7 ? 1.0 : 7.0;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.textSecondary.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  // Asse Y: emoji al posto dei numeri
                  const emojis = ['😞', '😕', '😐', '🙂', '😄'];
                  final i = v.round();
                  if (i < 0 || i > 4) return const SizedBox.shrink();
                  return Text(emojis[i], style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: intervalloX,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= _giorni.length) return const SizedBox.shrink();
                  final parts = _giorni[i].data.split('-');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${parts[2]}/${parts[1]}',
                      style: TextStyle(fontSize: 10, color: colors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: colors.accent,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: colors.accent,
                  strokeWidth: 0,
                ),
              ),
              // Area sotto la linea per dare profondità al grafico
              belowBarData: BarAreaData(
                show: true,
                color: colors.accent.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grafico routine: BarChart sugli ultimi 7 giorni ───────────────────────
  Widget _buildRoutineChart(AppColors colors) {
    // Uso solo la slice degli ultimi 7 giorni
    final slice = _giorni7;
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < slice.length; i++) {
      final g = slice[i];
      Color barColor;
      double value;

      if (!g.completato) {
        // Giorno senza check-in: barra quasi invisibile come placeholder
        barColor = colors.textSecondary.withValues(alpha: 0.15);
        value    = 0.2;
      } else {
        switch (g.routine) {
          case 0:  barColor = colors.success;                      value = 3; break; // Completata
          case 1:  barColor = colors.warning;                      value = 2; break; // Parziale
          default: barColor = colors.error.withValues(alpha: 0.6); value = 1;        // Non fatta
        }
      }

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: barColor,
            // Barre più larghe rispetto al grafico a 14 giorni: su 7 c'è più spazio
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: BarChart(
            BarChartData(
              maxY: 3.5,
              barGroups: barGroups,
              gridData:   const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // interval: 1 → mostro ogni giorno, su 7 non si sovrappongono
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= slice.length) return const SizedBox.shrink();
                      final parts = slice[i].data.split('-');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${parts[2]}/${parts[1]}',
                          style: TextStyle(fontSize: 9, color: colors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) {
                    final g = slice[group.x];
                    if (!g.completato) return null;
                    const labels = ['Sì ✅', 'In parte ⚡', 'No ❌'];
                    return BarTooltipItem(
                      labels[g.routine ?? 2],
                      TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legenda colori
        Row(
          children: [
            _LegendaDot(color: colors.success,                      label: 'Sì'),
            const SizedBox(width: 16),
            _LegendaDot(color: colors.warning,                      label: 'In parte'),
            const SizedBox(width: 16),
            _LegendaDot(color: colors.error.withValues(alpha: 0.6), label: 'No'),
            const SizedBox(width: 16),
            _LegendaDot(
              color: colors.textSecondary.withValues(alpha: 0.3),
              label: 'Non fatto',
            ),
          ],
        ),
      ],
    );
  }

  // ── Calendario check-in: griglia 4×7 con i 28 giorni intorno a oggi ──────
  Widget _buildCalendarioStreak(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Intestazione giorni della settimana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                .map((d) => SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildGrigliaDot(colors),
        ],
      ),
    );
  }

  Widget _buildGrigliaDot(AppColors colors) {
    // Il set dei giorni con check-in viene dai 14 giorni centrali
    final giorni14Set = {
      for (final g in _giorni14.where((g) => g.completato)) g.data
    };

    final oggi = DateTime.now();
    // Parto dal lunedì di 3 settimane fa per avere 4 righe complete
    final primoLunedi = oggi.subtract(Duration(days: oggi.weekday - 1 + 21));
    final giorni = List.generate(28, (i) => primoLunedi.add(Duration(days: i)));

    final rows = <Widget>[];
    for (int row = 0; row < 4; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final d          = giorni[row * 7 + col];
        final key        = _chiaveData(d);
        final completato = giorni14Set.contains(key);
        final isOggi     = key == _chiaveData(oggi);
        final futuro     = d.isAfter(oggi);

        cells.add(Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: futuro
                ? Colors.transparent
                : completato
                ? colors.accent
                : colors.background,
            shape: BoxShape.circle,
            // Bordo accent solo sul giorno corrente
            border: isOggi ? Border.all(color: colors.accent, width: 2) : null,
          ),
          child: futuro
              ? null // giorni futuri: cella vuota
              : completato
              ? Icon(Icons.check_rounded, size: 14, color: colors.textOnAccent)
              : Center(
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ));
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: cells,
      ));
    }
    return Column(children: rows);
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }

  // Placeholder quando non ci sono ancora dati per un grafico
  Widget _emptyState(String msg, AppColors colors) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        msg,
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
    );
  }
}

// ─── Modello dati per un singolo giorno ──────────────────────────────────────

class _GiornoStats {
  final String data;       // chiave YYYY-MM-DD
  final int?   mood;       // 0–4, null se non inserito
  final int?   routine;    // 0=completata, 1=parziale, 2=non fatta, null se assente
  final bool   completato; // true se il documento esiste in Firestore

  const _GiornoStats({
    required this.data,
    required this.mood,
    required this.routine,
    required this.completato,
  });
}

// ─── Card aggregato ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final AppColors colors;

  const _StatCard({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pallino colorato per la legenda del grafico routine ─────────────────────

class _LegendaDot extends StatelessWidget {
  final Color  color;
  final String label;

  const _LegendaDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
      ],
    );
  }
}