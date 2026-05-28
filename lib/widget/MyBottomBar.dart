import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/Home.dart';
import 'package:untitled/note.dart';
import 'package:untitled/inspo.dart';
import 'package:untitled/widget_tree.dart';

class MyBottomBar extends StatefulWidget {
  const MyBottomBar({super.key});

  @override
  State<MyBottomBar> createState() => _MyBottomBarState();
}

class _MyBottomBarState extends State<MyBottomBar> {
  final List<Widget> pages = [
    Home(),
    const Note(),
    WidgetTree(),
    const Inspo(),
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: Container(
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
                  selected: currentPage == 0,
                  onTap: () => setState(() => currentPage = 0),
                ),
                _NavItem(
                  icon: Icons.note_rounded,
                  label: 'Note',
                  selected: currentPage == 1,
                  onTap: () => setState(() => currentPage = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profilo',
                  selected: currentPage == 2,
                  onTap: () => setState(() => currentPage = 2),
                ),
                _NavItem(
                  icon: Icons.rocket_launch_outlined,
                  label: 'Ispirati',
                  selected: currentPage == 3,
                  onTap: () => setState(() => currentPage = 3),
                ),
              ],
            ),
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
              color: selected ? const Color(0xFF7A9CC6) : const Color(0xFF8A9BB5),
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