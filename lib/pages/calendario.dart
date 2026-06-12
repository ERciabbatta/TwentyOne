import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3A4A5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendario',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
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
              child: _caricamento
                  ? const SizedBox(
                height: 360,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7A9CC6),
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
                    color: const Color(0xFF3A4A5C),
                  ),
                  leftChevronIcon: const Icon(Icons.arrow_back_ios,
                      color: Color(0xFF7A9CC6), size: 18),
                  rightChevronIcon: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF7A9CC6), size: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EEF7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle:
                  TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
                  weekendStyle:
                  TextStyle(color: Color(0xFF7A9CC6), fontSize: 13),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_haCheckIn(day)) {
                      return _buildGiornoCheckIn(
                          day, const Color(0xFF66BB6A), Colors.white);
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    if (_haCheckIn(day)) {
                      return _buildGiornoCheckIn(
                          day, const Color(0xFF4CAF50), Colors.white,
                          bordo: true);
                    }
                    return _buildGiornoCheckIn(
                        day, const Color(0xFF7A9CC6), Colors.white);
                  },
                  outsideBuilder: (context, day, focusedDay) =>
                  const SizedBox.shrink(),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: const BoxDecoration(
                    color: Color(0xFF7A9CC6),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  defaultDecoration: BoxDecoration(
                    color: const Color(0xFFE8EEF7),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle:
                  const TextStyle(color: Color(0xFF3A4A5C)),
                  weekendDecoration: BoxDecoration(
                    color: const Color(0xFFE8EEF7),
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle:
                  const TextStyle(color: Color(0xFF7A9CC6)),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFFD0DCF0),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle:
                  const TextStyle(color: Color(0xFF3A4A5C)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legenda
            if (!_caricamento)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVoiceLegenda(
                      const Color(0xFF66BB6A), 'Check-in completato'),
                  const SizedBox(width: 20),
                  _buildVoiceLegenda(
                      const Color(0xFF7A9CC6), 'Oggi'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiornoCheckIn(DateTime day, Color sfondo, Color testo,
      {bool bordo = false}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sfondo,
        shape: BoxShape.circle,
        border: bordo
            ? Border.all(color: const Color(0xFF2E7D32), width: 2)
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
          style: const TextStyle(
            color: Color(0xFF8A9BB5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
