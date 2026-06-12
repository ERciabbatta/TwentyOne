import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreaNota extends StatefulWidget {
  final int giornoPreselezionato;

  const CreaNota({super.key, required this.giornoPreselezionato});

  @override
  State<CreaNota> createState() => _CreaNotaState();
}

class _CreaNotaState extends State<CreaNota> {
  final TextEditingController _controllerTesto = TextEditingController();
  TimeOfDay? _orarioInizio;
  TimeOfDay? _orarioFine;
  String? _pickerAperto;
  int _oreSelezionate = 0;
  int _minutiSelezionati = 0;
  late List<bool> _giorniSelezionati;

  final List<String> _giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    _giorniSelezionati = List.generate(7, (i) => i == widget.giornoPreselezionato);
  }

  void _apriPicker(String quale) {
    final orario = quale == 'inizio' ? _orarioInizio : _orarioFine;
    setState(() {
      _pickerAperto = quale;
      _oreSelezionate = orario?.hour ?? TimeOfDay.now().hour;
      _minutiSelezionati = orario?.minute ?? TimeOfDay.now().minute;
    });
  }

  void _confermaOrario() {
    final orario = TimeOfDay(hour: _oreSelezionate, minute: _minutiSelezionati);
    setState(() {
      if (_pickerAperto == 'inizio') {
        _orarioInizio = orario;
      } else {
        _orarioFine = orario;
      }
      _pickerAperto = null;
    });
  }

  String _formatOrario(TimeOfDay? orario) {
    if (orario == null) return '--:--';
    final ore = orario.hour.toString().padLeft(2, '0');
    final minuti = orario.minute.toString().padLeft(2, '0');
    return '$ore:$minuti';
  }

  Future<void> _salvaNota(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_orarioInizio == null || _orarioFine == null) return;

    final giorniScelti = <int>[];
    for (int i = 0; i < 7; i++) {
      if (_giorniSelezionati[i]) giorniScelti.add(i);
    }
    if (giorniScelti.isEmpty) return;

    final nuovoIniziMin = _orarioInizio!.hour * 60 + _orarioInizio!.minute;
    final nuovoFineMin = _orarioFine!.hour * 60 + _orarioFine!.minute;

    final snapshot = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .collection('note')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final inizioStr = data['inizio'] as String? ?? '';
      final fineStr = data['fine'] as String? ?? '';
      final giorniEsistenti = List<int>.from(data['giorni'] ?? []);

      final haGiornoInComune = giorniScelti.any((g) => giorniEsistenti.contains(g));
      if (!haGiornoInComune) continue;

      if (inizioStr == '--:--' || fineStr == '--:--') continue;

      final partiInizio = inizioStr.split(':');
      final partiFine = fineStr.split(':');
      final esistenteIniziMin = int.parse(partiInizio[0]) * 60 + int.parse(partiInizio[1]);
      final esistenteFineMin = int.parse(partiFine[0]) * 60 + int.parse(partiFine[1]);

      final siSovrappone = nuovoIniziMin < esistenteFineMin && nuovoFineMin > esistenteIniziMin;

      if (siSovrappone) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orario sovrapposto a una nota esistente.'),
              backgroundColor: Color(0xFF7A9CC6),
            ),
          );
        }
        return;
      }
    }

    await FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .collection('note')
        .add({
      'testo': _controllerTesto.text,
      'inizio': _formatOrario(_orarioInizio),
      'fine': _formatOrario(_orarioFine),
      'giorni': giorniScelti,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (context.mounted) Navigator.pop(context);
  }

  Widget _scrollColonna({
    required int valore,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final controller = FixedExtentScrollController(initialItem: valore);
    return SizedBox(
      width: 64,
      height: 140,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        perspective: 0.003,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max,
          builder: (context, index) {
            final selezionato = index == valore;
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: selezionato ? 26 : 18,
                  fontWeight: selezionato ? FontWeight.w600 : FontWeight.w400,
                  color: selezionato
                      ? const Color(0xFF3A4A5C)
                      : const Color(0xFFB8C8DA),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _inlinePicker() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _pickerAperto == 'inizio' ? 'Orario di inizio' : 'Orario di fine',
          style: const TextStyle(
            color: Color(0xFF8A9BB5),
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scrollColonna(
                valore: _oreSelezionate,
                max: 24,
                onChanged: (v) => setState(() => _oreSelezionate = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7A9CC6),
                  ),
                ),
              ),
              _scrollColonna(
                valore: _minutiSelezionati,
                max: 60,
                onChanged: (v) => setState(() => _minutiSelezionati = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _pickerAperto = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Color(0xFF3A4A5C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _confermaOrario,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A9CC6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Conferma',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuova nota',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A4A5C),
              ),
            ),

            if (_pickerAperto == null) ...[
              const SizedBox(height: 16),

              TextField(
                controller: _controllerTesto,
                style: const TextStyle(color: Color(0xFF3A4A5C)),
                decoration: InputDecoration(
                  labelText: 'Testo',
                  labelStyle: const TextStyle(color: Color(0xFF8A9BB5)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7A9CC6)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE8EEF7),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Giorni',
                style: TextStyle(
                  color: Color(0xFF8A9BB5),
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final selezionato = _giorniSelezionati[index];
                  return GestureDetector(
                    onTap: () => setState(() => _giorniSelezionati[index] = !selezionato),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selezionato
                            ? const Color(0xFF7A9CC6)
                            : const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _giorni[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selezionato
                                ? Colors.white
                                : const Color(0xFF8A9BB5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _apriPicker('inizio'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Inizio',
                            style: TextStyle(
                              color: Color(0xFF8A9BB5),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatOrario(_orarioInizio),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF3A4A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Color(0xFF7A9CC6), size: 22),
                  GestureDetector(
                    onTap: () => _apriPicker('fine'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Fine',
                            style: TextStyle(
                              color: Color(0xFF8A9BB5),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatOrario(_orarioFine),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF3A4A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _salvaNota(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A9CC6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aggiungi Nota',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            if (_pickerAperto != null) _inlinePicker(),
          ],
        ),
      ),
    );
  }
}
