import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Dialog modale per creare una nuova nota ricorrente (es. promemoria
/// legato ad una routine): testo, giorni della settimana e fascia oraria
/// di validità. Usato dalla pagina `note.dart`.
class CreaNota extends StatefulWidget {
  /// Indice (0=Lun ... 6=Dom) del giorno da preselezionare all'apertura,
  /// tipicamente il giorno corrente.
  final int giornoPreselezionato;

  const CreaNota({super.key, required this.giornoPreselezionato});

  @override
  State<CreaNota> createState() => _CreaNotaState();
}

class _CreaNotaState extends State<CreaNota> {
  /// Testo libero della nota inserito dall'utente.
  final TextEditingController _controllerTesto = TextEditingController();

  /// Orario di inizio validità della nota, `null` finché non impostato.
  TimeOfDay? _orarioInizio;

  /// Orario di fine validità della nota, `null` finché non impostato.
  TimeOfDay? _orarioFine;

  /// Quale picker orario è attualmente aperto: `'inizio'`, `'fine'` o
  /// `null` se nessuno (mostra il form principale).
  String? _pickerAperto;

  /// Valore ore momentaneamente selezionato nella rotella del picker orario.
  int _oreSelezionate = 0;

  /// Valore minuti momentaneamente selezionato nella rotella del picker orario.
  int _minutiSelezionati = 0;

  /// Flag di selezione per ciascuno dei 7 giorni della settimana.
  late List<bool> _giorniSelezionati;

  final List<String> _giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    _giorniSelezionati = List.generate(7, (i) => i == widget.giornoPreselezionato);
  }

  /// Apre il picker orario a rotella per `'inizio'` o `'fine'`,
  /// precaricando la selezione con l'orario già impostato (o quello
  /// corrente se non ancora impostato).
  void _apriPicker(String quale) {
    final orario = quale == 'inizio' ? _orarioInizio : _orarioFine;
    setState(() {
      _pickerAperto = quale;
      _oreSelezionate = orario?.hour ?? TimeOfDay.now().hour;
      _minutiSelezionati = orario?.minute ?? TimeOfDay.now().minute;
    });
  }

  /// Salva l'orario selezionato nella rotella (inizio o fine, in base a
  /// [_pickerAperto]) e richiude il picker tornando al form principale.
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

  /// Formatta un [TimeOfDay] come stringa `HH:MM`, oppure `--:--` se `null`.
  String _formatOrario(TimeOfDay? orario) {
    if (orario == null) return '--:--';
    final ore = orario.hour.toString().padLeft(2, '0');
    final minuti = orario.minute.toString().padLeft(2, '0');
    return '$ore:$minuti';
  }

  /// Mostra una SnackBar di errore con il messaggio indicato.
  void _mostraErrore(BuildContext context, String messaggio) {
    if (!context.mounted) return;
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: colors.error,
      ),
    );
  }

  /// Valida i campi del form (testo, orari, giorni selezionati, assenza
  /// di sovrapposizioni con note esistenti sugli stessi giorni) e, se
  /// tutto è corretto, salva la nuova nota su Firestore e chiude il dialog.
  Future<void> _salvaNota(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_controllerTesto.text.trim().isEmpty) {
      _mostraErrore(context, 'Scrivi il testo della nota.');
      return;
    }

    if (_orarioInizio == null || _orarioFine == null) {
      _mostraErrore(context, 'Imposta orario di inizio e fine.');
      return;
    }

    final giorniScelti = <int>[];
    for (int i = 0; i < 7; i++) {
      if (_giorniSelezionati[i]) giorniScelti.add(i);
    }
    if (giorniScelti.isEmpty) {
      _mostraErrore(context, 'Seleziona almeno un giorno.');
      return;
    }

    if (_orarioFine!.hour * 60 + _orarioFine!.minute <=
        _orarioInizio!.hour * 60 + _orarioInizio!.minute) {
      _mostraErrore(context, 'L\'orario di fine deve essere dopo l\'inizio.');
      return;
    }

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
            SnackBar(
              content: const Text('Orario sovrapposto a una nota esistente.'),
              backgroundColor: AppColors.of(context).accent,
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

  /// Costruisce una colonna a rotella scorrevole (usata per ore e minuti
  /// nel picker orario), con l'elemento centrato evidenziato.
  Widget _scrollColonna({
    required int valore,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final colors = AppColors.of(context);
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
                      ? colors.textPrimary
                      : colors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Costruisce il picker orario inline (rotelle ore/minuti + pulsanti
  /// Annulla/Conferma), mostrato al posto del form quando [_pickerAperto]
  /// non è `null`.
  Widget _inlinePicker() {
    final colors = AppColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _pickerAperto == 'inizio' ? 'Orario di inizio' : 'Orario di fine',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
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
                    color: colors.accent,
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
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: colors.textPrimary,
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
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Conferma',
                      style: TextStyle(
                        color: colors.textOnAccent,
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

  /// Costruisce il dialog: mostra il form principale (testo, giorni,
  /// selettori orario) oppure il picker orario inline, in base allo
  /// stato di [_pickerAperto].
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuova nota',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),

            if (_pickerAperto == null) ...[
              const SizedBox(height: 16),

              TextField(
                controller: _controllerTesto,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Testo',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Giorni',
                style: TextStyle(
                  color: colors.textSecondary,
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
                            ? colors.accent
                            : colors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _giorni[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selezionato
                                ? colors.textOnAccent
                                : colors.textSecondary,
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
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Inizio',
                            style: TextStyle(
                              color: colors.textSecondary,
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
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: colors.accent, size: 22),
                  GestureDetector(
                    onTap: () => _apriPicker('fine'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Fine',
                            style: TextStyle(
                              color: colors.textSecondary,
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
                              color: colors.textPrimary,
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
                    backgroundColor: colors.accent,
                    foregroundColor: colors.textOnAccent,
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

