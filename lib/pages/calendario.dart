import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/app_colors.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  Set<String> _giorniCheckIn = {};
  bool _caricamento = true;

  @override
  void initState() {
    super.initState();
    _caricaCheckIn();
  }

  Future<void> _caricaCheckIn() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) {
      setState(() => _caricamento = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .collection('checkin')
          .get();

      setState(() {
        _giorniCheckIn = snapshot.docs.map((d) => d.id).toSet();
        _caricamento = false;
      });
    } catch (_) {
      setState(() => _caricamento = false);
    }
  }

  String _chiaveData(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

  bool _haCheckIn(DateTime giorno) =>
      _giorniCheckIn.contains(_chiaveData(giorno));

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendario',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
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
              child: _caricamento
                  ? SizedBox(
                height: 360,
                child: Center(
                  child: CircularProgressIndicator(
                    color: colors.accent,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  leftChevronIcon: Icon(Icons.arrow_back_ios,
                      color: colors.accent, size: 18),
                  rightChevronIcon: Icon(Icons.arrow_forward_ios,
                      color: colors.accent, size: 18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle:
                  TextStyle(color: colors.textSecondary, fontSize: 13),
                  weekendStyle:
                  TextStyle(color: colors.accent, fontSize: 13),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_haCheckIn(day)) {
                      return _buildGiornoCheckIn(
                          day, colors.success, colors.textOnAccent);
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    if (_haCheckIn(day)) {
                      return _buildGiornoCheckIn(
                          day, colors.success, colors.textOnAccent,
                          bordo: true);
                    }
                    return _buildGiornoCheckIn(
                        day, colors.accent, colors.textOnAccent);
                  },
                  outsideBuilder: (context, day, focusedDay) =>
                  const SizedBox.shrink(),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                      color: colors.textOnAccent, fontWeight: FontWeight.bold),
                  defaultDecoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle:
                  TextStyle(color: colors.textPrimary),
                  weekendDecoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle:
                  TextStyle(color: colors.accent),
                  selectedDecoration: BoxDecoration(
                    color: colors.surfaceSelected,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle:
                  TextStyle(color: colors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (!_caricamento)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVoiceLegenda(
                      colors.success, 'Check-in completato'),
                  const SizedBox(width: 20),
                  _buildVoiceLegenda(
                      colors.accent, 'Oggi'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiornoCheckIn(DateTime day, Color sfondo, Color testo,
      {bool bordo = false}) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sfondo,
        shape: BoxShape.circle,
        border: bordo
            ? Border.all(color: colors.success, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: testo,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceLegenda(Color colore, String etichetta) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colore,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etichetta,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

