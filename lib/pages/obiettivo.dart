import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';

class OnboardingObiettivo extends StatefulWidget {

  final bool modifica;

  final VoidCallback? onCompletato;
  const OnboardingObiettivo({super.key, this.modifica = false, this.onCompletato});

  @override
  State<OnboardingObiettivo> createState() => _OnboardingObiettivoState();
}

class _OnboardingObiettivoState extends State<OnboardingObiettivo> {
  final _controller = TextEditingController();
  bool _caricamento = false;
  String? _errore;

  final List<String> _suggerimenti = [
    'Meditare ogni mattina',
    'Correre 3 volte a settimana',
    'Leggere 20 minuti al giorno',
    'Smettere di fumare',
    'Mangiare sano',
    'Studiare una nuova lingua',
    'Dormire prima di mezzanotte',
    'Fare stretching ogni sera',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.modifica) _caricaObiettivoEsistente();
  }

  Future<void> _caricaObiettivoEsistente() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .get();
    final obiettivo = doc.data()?['obiettivo'] as String?;
    if (obiettivo != null && mounted) {
      _controller.text = obiettivo;
    }
  }

  Future<void> _salva() async {
    final testo = _controller.text.trim();
    if (testo.isEmpty) {
      setState(() => _errore = 'Scrivi il tuo obiettivo per continuare.');
      return;
    }
    if (testo.length > 80) {
      setState(() => _errore = 'Massimo 80 caratteri.');
      return;
    }

    final uid = Auth().currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _caricamento = true;
      _errore = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .set({'obiettivo': testo}, SetOptions(merge: true));

      if (!mounted) return;
      if (widget.modifica) {
        Navigator.pop(context, testo);
      } else {
        widget.onCompletato?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _errore = 'Errore nel salvataggio. Riprova.');
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: widget.modifica
          ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF3A4A5C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Il mio obiettivo',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A4A5C),
          ),
        ),
      )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: widget.modifica ? 24 : 60),

              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EEF7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: Color(0xFF7A9CC6), size: 36),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  widget.modifica
                      ? 'Modifica il tuo obiettivo'
                      : 'Cosa vuoi costruire\nin 21 giorni?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A4A5C),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  widget.modifica
                      ? 'Puoi cambiarlo quando vuoi.'
                      : 'Scegli un\'abitudine concreta e tienila\ncostante per 21 giorni.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8A9BB5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _controller,
                maxLength: 80,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Color(0xFF3A4A5C),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Es. Meditare ogni mattina',
                  hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                  counterStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFE8EEF7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: Color(0xFF7A9CC6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (_) {
                  if (_errore != null) setState(() => _errore = null);
                },
              ),

              if (_errore != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errore!,
                  style: const TextStyle(
                      color: Color(0xFFE57373), fontSize: 13),
                ),
              ],

              const SizedBox(height: 16),

              Text(
                'Oppure scegli uno di questi:',
                style: const TextStyle(
                    color: Color(0xFF8A9BB5), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggerimenti.map((s) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = s;
                      if (_errore != null) setState(() => _errore = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFD0DCF0), width: 1),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: Color(0xFF3A4A5C),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _caricamento ? null : _salva,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A9CC6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _caricamento
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2
                      ),
                    )
                        : Text(
                      widget.modifica ? 'Salva' : 'Inizia i 21 giorni →',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
