import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/widget/servizio_notifiche.dart';

class Notifiche extends StatefulWidget {
  const Notifiche({super.key});

  @override
  State<Notifiche> createState() => _NotificheState();
}

class _NotificheState extends State<Notifiche> {
  bool _eventiAttivi = true;
  bool _motivazionaliAttive = true;
  bool _checkInAttivo = true;
  bool _caricamento = true;

  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _caricaPreferenze();
  }

  Future<void> _caricaPreferenze() async {
    final eventi = await _service.getEventiAttivi();
    final motivazionali = await _service.getMotivazionaliAttive();
    final checkIn = await _service.getCheckInAttivo();
    setState(() {
      _eventiAttivi = eventi;
      _motivazionaliAttive = motivazionali;
      _checkInAttivo = checkIn;
      _caricamento = false;
    });
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
          'Notifiche',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
      ),
      body: _caricamento
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            Text(
              'Promemoria',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A4A5C),
              ),
            ),
            const SizedBox(height: 12),

            _ToggleTile(
              icon: Icons.event_note_rounded,
              label: 'Notifiche eventi',
              descrizione: '15 minuti prima di ogni nota',
              value: _eventiAttivi,
              onChanged: (val) async {
                setState(() => _eventiAttivi = val);
                await _service.setEventiAttivi(val);
              },
            ),

            const SizedBox(height: 10),

            _ToggleTile(
              icon: Icons.nightlight_round,
              label: 'Check-in serale',
              descrizione: 'Promemoria alle 22:00 per il check-in',
              value: _checkInAttivo,
              onChanged: (val) async {
                setState(() => _checkInAttivo = val);
                await _service.setCheckInAttivo(val);
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Ispirazione',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A4A5C),
              ),
            ),
            const SizedBox(height: 12),

            _ToggleTile(
              icon: Icons.auto_awesome_rounded,
              label: 'Frasi motivazionali',
              descrizione: 'Frasi di ispirazione durante la giornata',
              value: _motivazionaliAttive,
              onChanged: (val) async {
                setState(() => _motivazionaliAttive = val);
                await _service.setMotivazionaliAttive(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descrizione;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.descrizione,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7A9CC6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF3A4A5C),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descrizione,
                  style: const TextStyle(
                    color: Color(0xFF8A9BB5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF7A9CC6),
          ),
        ],
      ),
    );
  }
}