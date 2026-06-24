import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twentyone/widget/app_colors.dart';

import 'package:twentyone/pages/home.dart';
import 'package:twentyone/pages/note.dart';
import 'package:twentyone/pages/inspo.dart';
import 'package:twentyone/pages/profilo.dart';

class MyBottomBar extends StatefulWidget {
  const MyBottomBar({super.key});

  @override
  State<MyBottomBar> createState() => _MyBottomBarState();
}

class _MyBottomBarState extends State<MyBottomBar> {
  int _currentPage = 0;

  // Una Key diversa per ogni "visita" alla tab Home forza la ricostruzione

  int _homeRebuildCount = 0;

  List<Widget> get _pages => [
    Home(key: ValueKey('home_$_homeRebuildCount')),
    const Note(),
    const Profilo(),
    const Inspo(),
  ];

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
