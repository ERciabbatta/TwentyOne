import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twentyone/pages/home.dart';
import 'package:twentyone/pages/note.dart';
import 'package:twentyone/pages/inspo.dart';
import 'package:twentyone/pages/profilo.dart';

/// Versione storica (snake_case) della shell di navigazione principale.
///
/// Logicamente equivalente a `MyBottomBar` (versione PascalCase più
/// recente), ma con colori fissi (non segue il tema chiaro/scuro tramite
/// `AppColors`). Mantenuta per compatibilità con import esistenti nel
/// resto del codice.
// ignore: camel_case_types
class my_bottom_bar extends StatefulWidget {
  const my_bottom_bar({super.key});

  @override
  State<my_bottom_bar> createState() => _my_bottom_barState();
}

// ignore: camel_case_types
class _my_bottom_barState extends State<my_bottom_bar> {
  /// Indice della tab attualmente visibile (0=Home, 1=Note, 2=Profilo, 3=Ispirati).
  int _currentPage = 0;

  // Una Key diversa per ogni "visita" alla tab Home forza la ricostruzione
  // del widget (e quindi initState/_caricaDatiUtente) ogni volta che torni
  // su quella tab, cosi' streak/obiettivo/giorni rimanenti sono sempre aggiornati.
  int _homeRebuildCount = 0;

  /// Elenco ordinato delle pagine associate alle tab della barra.
  List<Widget> get _pages => [
    Home(key: ValueKey('home_$_homeRebuildCount')),
    const Note(),
    const Profilo(),
    const Inspo(),
  ];

  /// Gestisce il tap su una voce della barra: aggiorna la tab corrente e,
  /// se si sta rientrando sulla Home, incrementa il contatore di rebuild.
  void _onTap(int index) {
    setState(() {
      if (index == 0 && _currentPage != 0) {
        _homeRebuildCount++;
      }
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentPage],
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentPage,
        onTap: _onTap,
      ),
    );
  }
}

/// Barra di navigazione inferiore vera e propria: renderizza le quattro
/// voci (`_NavItem`) ed evidenzia quella corrispondente a [currentIndex].
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.note_rounded,
                label: 'Note',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profilo',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.rocket_launch_outlined,
                label: 'Ispirati',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Singola voce della barra di navigazione: mostra un'icona e, solo se
/// [selected] è vero, anche l'etichetta testuale accanto.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EEF7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xFF7A9CC6)
                  : const Color(0xFF8A9BB5),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A4A5C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}