import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Note(),
    WidgetTree(),
    Inspo(),
  ];

  int currentPage = 0;
  final GlobalKey _barKey = GlobalKey();

  void _handleBarDrag(Offset localPosition) {
    final RenderBox? box =
    _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final width = box.size.width;
    final x = localPosition.dx.clamp(0.0, width);
    final index = (x / width * 4).floor().clamp(0, 3);

    if (index != currentPage) {
      setState(() => currentPage = index);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: Platform.isIOS,
      body: IndexedStack(
        index: currentPage,
        children: pages,
      ),
      bottomNavigationBar: Platform.isIOS
          ? _buildLiquidGlassBar()
          : _buildClassicBar(),
    );
  }

  Widget _buildLiquidGlassBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: GestureDetector(
          onPanStart: (d) => _handleBarDrag(d.localPosition),
          onPanUpdate: (d) => _handleBarDrag(d.localPosition),
          child: OCLiquidGlassGroup(
            key: _barKey,
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.04,
              blurRadiusPx: 40.0,
              specStrength: 8.0,
              lightbandColor: Colors.white,
              lightbandStrength: 0.15,
            ),
            child: OCLiquidGlass(
              height: 76,
              borderRadius: 22,
              color: Colors.white.withOpacity(0.08),
              shadow: BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 32,
                offset: const Offset(0, 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(selected),
                size: 24,
                color: selected
                    ? (isIOS
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF7A9CC6))
                    : (isIOS
                    ? Colors.white.withOpacity(0.45)
                    : const Color(0xFF8A9BB5)),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? (isIOS
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF3A4A5C))
                    : (isIOS
                    ? Colors.white.withOpacity(0.45)
                    : const Color(0xFF8A9BB5)),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}