import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twentyone/widget/app_colors.dart';

import 'package:twentyone/pages/home.dart';
import 'package:twentyone/pages/note.dart';
import 'package:twentyone/pages/inspo.dart';
import 'package:twentyone/pages/profilo.dart';

/// Shell principale dell'app dopo il login: gestisce la navigazione fra
/// le quattro sezioni (Home, Note, Profilo, Ispirati) tramite una barra
/// di navigazione inferiore custom.
class MyBottomBar extends StatefulWidget {
  const MyBottomBar({super.key});

  @override
  State<MyBottomBar> createState() => _MyBottomBarState();
}

class _MyBottomBarState extends State<MyBottomBar> {
  /// Indice della tab attualmente visibile (0=Home, 1=Note, 2=Profilo, 3=Ispirati).
  int _currentPage = 0;

  /// Contatore incrementato ad ogni rientro sulla tab Home: usato come
  /// parte della Key del widget Home per forzarne la ricostruzione completa
  /// (e quindi il refresh dei dati) ogni volta che l'utente ci torna.
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
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
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
/// [selected] è vero, anche l'etichetta testuale accanto (per risparmiare
/// spazio quando la voce non è attiva).
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
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colors.accent : colors.textSecondary,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}