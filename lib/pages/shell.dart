import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_project/pages/mapWindow.dart';
import 'package:my_first_project/pages/profile.dart';
import 'package:my_first_project/pages/reportPage.dart';
import '../main.dart';
import 'depricated/mapPage.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<Widget> _pages = const [MapPage(), ReportPage(), ProfilePage()];
  int _currentIndex = 0;

  void _onTapp(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTapp,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NMColors.surface,
        border: Border(top: BorderSide(color: NMColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: "Map",
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(1),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: NMColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: NMColors.green.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF0A1A0C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: currentIndex == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: currentIndex == 1
                              ? NMColors.green
                              : NMColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: "Profile",
                active: currentIndex == 2,
                onTap: () => onTap(2),
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
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? NMColors.green : NMColors.muted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? NMColors.green : NMColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
