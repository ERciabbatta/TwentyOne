import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:twentyone/pages/home.dart';
import 'package:twentyone/pages/note.dart';
import 'package:twentyone/pages/inspo.dart';
import 'package:twentyone/widget/widget_tree.dart';

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
      extendBody: Platform.isIOS,
      body: pages[currentPage],
      bottomNavigationBar: Platform.isIOS
          ? _buildLiquidGlassBar()
          : _buildClassicBar(),
    );
  }

  Widget _buildLiquidGlassBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: OCLiquidGlassGroup(
          settings: const OCLiquidGlassSettings(
            refractStrength: -0.06,
            blurRadiusPx: 2.0,
            specStrength: 18.0,
            lightbandColor: Colors.white,
            lightbandStrength: 0.5,
          ),
          child: OCLiquidGlass(
            height: 68,
            borderRadius: 34,
            color: Colors.white.withOpacity(0.15),
            shadow: BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _buildClassicBar() {
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
    final isIOS = Platform.isIOS;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isIOS ? Colors.white.withOpacity(0.4) : const Color(0xFFE8EEF7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isIOS ? 20 : 16),
          border: selected && isIOS
              ? Border.all(color: Colors.white.withOpacity(0.6), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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