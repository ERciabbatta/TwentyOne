import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
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
        child: Container(
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
          child: TableCalendar(
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
              leftChevronIcon: const Icon(Icons.arrow_back_ios, color: Color(0xFF7A9CC6), size: 18),
              rightChevronIcon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF7A9CC6), size: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEF7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
              weekendStyle: TextStyle(color: Color(0xFF7A9CC6), fontSize: 13),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: const BoxDecoration(
                color: Color(0xFF7A9CC6),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              defaultDecoration: BoxDecoration(
                color: const Color(0xFFE8EEF7),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Color(0xFF3A4A5C)),
              weekendDecoration: BoxDecoration(
                color: const Color(0xFFE8EEF7),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Color(0xFF7A9CC6)),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFD0DCF0),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Color(0xFF3A4A5C)),
            ),
          ),
        ),
      ),
    );
  }
}