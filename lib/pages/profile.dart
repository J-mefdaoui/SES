import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'Auth/login.dart';

// =============================================================================
// BADGE MODEL
// =============================================================================

class _Badge {
  final String emoji;
  final String name;
  final String description;
  final bool unlocked;
  final Color color;

  const _Badge({
    required this.emoji,
    required this.name,
    required this.description,
    required this.unlocked,
    required this.color,
  });
}

const _badges = [
  _Badge(
    emoji: '🔥',
    name: '7-day streak',
    description: 'Report 7 days in a row',
    unlocked: true,
    color: NMColors.amber,
  ),
  _Badge(
    emoji: '📍',
    name: 'First reporter',
    description: 'First to report a location',
    unlocked: true,
    color: NMColors.green,
  ),
  _Badge(
    emoji: '🔬',
    name: 'Data guardian',
    description: 'Submit 25+ reports',
    unlocked: true,
    color: Color(0xFFA78BFA),
  ),
  _Badge(
    emoji: '🏆',
    name: 'Top reporter',
    description: 'Reach top 10 in your city',
    unlocked: false,
    color: NMColors.muted,
  ),
  _Badge(
    emoji: '🗺️',
    name: 'Explorer',
    description: 'Report in 5 neighborhoods',
    unlocked: false,
    color: NMColors.muted,
  ),
];

// =============================================================================
// NEIGHBORHOOD MODEL
// =============================================================================

class _Neighborhood {
  final String name;
  final int reportCount;
  final bool isUser;

  const _Neighborhood(this.name, this.reportCount, {this.isUser = false});
}

const _leaderboard = [
  _Neighborhood('Tunis', 143),
  _Neighborhood('Beja', 103),
  _Neighborhood('Jendouba', 79, isUser: true),
  _Neighborhood('Kef', 61),
  _Neighborhood('Karaouen', 44),
];

// =============================================================================
// PROFILE PAGE
// =============================================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NMColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: NMColors.muted,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ProfileHero(),
          const SizedBox(height: 16),
          _StatGrid(),
          const SizedBox(height: 20),
          const _SectionHeader('Badges'),
          const SizedBox(height: 10),
          _BadgeGrid(),
          const SizedBox(height: 20),
          const _SectionHeader('State leaderboard'),
          const SizedBox(height: 10),
          _Leaderboard(),
          const SizedBox(height: 20),
          const _SectionHeader('Activity · last 30 days'),
          const SizedBox(height: 10),
          _ActivityBar(),
        ],
      ),
    );
  }
}

// =============================================================================
// SETTINGS BOTTOM SHEET
// =============================================================================

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _notificationsEnabled = true;
  bool _emailAlerts = false;
  String _distanceUnit = 'km';
  double _defaultZoom = 12.0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pop(); // close sheet
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NMColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: NMColors.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: NMColors.muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: NMColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: NMColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── ACCOUNT ──────────────────────────────────────────────────────
            _SheetSectionLabel('Account'),
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Edit profile',
              onTap: () {
                // TODO: navigate to edit profile page
              },
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.logout,
              label: 'Log out',
              labelColor: NMColors.red,
              iconColor: NMColors.red,
              onTap: _logout,
            ),

            const SizedBox(height: 16),

            // ── NOTIFICATIONS ─────────────────────────────────────────────────
            _SheetSectionLabel('Notifications'),
            _SettingsToggle(
              icon: Icons.notifications_outlined,
              label: 'Push notifications',
              value: _notificationsEnabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _notificationsEnabled = v);
                // TODO: save to shared_preferences
              },
            ),
            _SettingsDivider(),
            _SettingsToggle(
              icon: Icons.email_outlined,
              label: 'Email alerts',
              value: _emailAlerts,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _emailAlerts = v);
                // TODO: save to shared_preferences
              },
            ),

            const SizedBox(height: 16),

            // ── MAP PREFERENCES ───────────────────────────────────────────────
            _SheetSectionLabel('Map preferences'),

            // Distance unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.straighten_outlined,
                    size: 18,
                    color: NMColors.muted,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Distance unit',
                      style: TextStyle(color: NMColors.text, fontSize: 14),
                    ),
                  ),
                  _SegmentedPicker(
                    options: const ['km', 'mi'],
                    selected: _distanceUnit,
                    onSelect: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _distanceUnit = v);
                      // TODO: save to shared_preferences
                    },
                  ),
                ],
              ),
            ),

            _SettingsDivider(),

            // Default zoom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.zoom_in_outlined,
                    size: 18,
                    color: NMColors.muted,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Default zoom',
                      style: TextStyle(color: NMColors.text, fontSize: 14),
                    ),
                  ),
                  Text(
                    _defaultZoom.toStringAsFixed(0),
                    style: const TextStyle(
                      color: NMColors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: NMColors.green,
                  inactiveTrackColor: NMColors.border,
                  thumbColor: NMColors.green,
                  overlayColor: NMColors.green.withOpacity(0.12),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: _defaultZoom,
                  min: 8,
                  max: 16,
                  divisions: 8,
                  onChanged: (v) {
                    setState(() => _defaultZoom = v);
                    // TODO: save to shared_preferences
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── ABOUT ─────────────────────────────────────────────────────────
            _SheetSectionLabel('About'),
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'App version',
              trailing: const Text(
                'v0.1.0 MVP',
                style: TextStyle(color: NMColors.muted, fontSize: 12),
              ),
              onTap: null,
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Privacy policy',
              onTap: () {
                // TODO: launch privacy policy URL
              },
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.code_outlined,
              label: 'Open source licences',
              onTap: () => showLicensePage(context: context),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SETTINGS SHEET COMPONENTS
// =============================================================================

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: NMColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color labelColor;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.labelColor = NMColors.text,
    this.iconColor = NMColors.muted,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: NMColors.green.withOpacity(0.05),
      highlightColor: NMColors.green.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 14),
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, size: 16, color: NMColors.muted),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NMColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: NMColors.text, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: NMColors.green,
            activeTrackColor: NMColors.green.withOpacity(0.25),
            inactiveThumbColor: NMColors.muted,
            inactiveTrackColor: NMColors.surface,
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 50),
      color: NMColors.border,
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final active = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? NMColors.green.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: active
                    ? Border.all(
                        color: NMColors.green.withOpacity(0.4),
                        width: 0.5,
                      )
                    : null,
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: active ? NMColors.green : NMColors.muted,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// PROFILE HERO — uses Firebase Auth for real name, photo, initials
// =============================================================================

class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    String initials = '';
    if (displayName.isNotEmpty && displayName != 'User') {
      final parts = displayName.split(' ');
      initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : displayName[0].toUpperCase();
    } else if (email.isNotEmpty) {
      initials = email[0].toUpperCase();
    } else {
      initials = '?';
    }

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NMColors.green.withOpacity(0.12),
            border: Border.all(
              color: NMColors.green.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsWidget(initials),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : _initialsWidget(initials),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: NMColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: NMColors.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    email.isNotEmpty ? email : 'Tunis · Joined Jan 2025',
                    style: const TextStyle(color: NMColors.muted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: NMColors.green,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// STAT GRID
// =============================================================================

class _StatGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '47', label: 'Reports'),
        const SizedBox(width: 8),
        _StatCard(value: '3', label: 'visited'),
        const SizedBox(width: 8),
        _StatCard(value: '#12', label: 'City rank', valueColor: NMColors.amber),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor = NMColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: NMColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NMColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: NMColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BADGE GRID
// =============================================================================

class _BadgeGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _badges.length,
      itemBuilder: (_, i) => _BadgeTile(badge: _badges[i]),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      preferBelow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.unlocked
                  ? badge.color.withOpacity(0.12)
                  : NMColors.surface,
              border: Border.all(
                color: badge.unlocked
                    ? badge.color.withOpacity(0.35)
                    : NMColors.border,
                width: badge.unlocked ? 1 : 0.5,
              ),
            ),
            child: Center(
              child: badge.unlocked
                  ? Text(badge.emoji, style: const TextStyle(fontSize: 20))
                  : const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: NMColors.muted,
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            badge.name,
            style: TextStyle(
              color: badge.unlocked ? NMColors.text : NMColors.muted,
              fontSize: 9,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEADERBOARD
// =============================================================================

class _Leaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final maxCount = _leaderboard.first.reportCount;
    return Container(
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: _leaderboard.asMap().entries.map((e) {
          final idx = e.key;
          final n = e.value;
          final isLast = idx == _leaderboard.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: n.isUser
                  ? NMColors.green.withOpacity(0.05)
                  : Colors.transparent,
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: NMColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: n.isUser ? NMColors.green : NMColors.muted,
                      fontSize: 13,
                      fontWeight: n.isUser
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        n.name,
                        style: TextStyle(
                          color: n.isUser ? NMColors.green : NMColors.text,
                          fontSize: 13,
                          fontWeight: n.isUser
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (n.isUser) ...[
                        const SizedBox(width: 5),
                        const Text(
                          '✦ you',
                          style: TextStyle(color: NMColors.green, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: n.reportCount / maxCount,
                      minHeight: 3,
                      backgroundColor: NMColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        n.isUser ? NMColors.green : NMColors.greenDim,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${n.reportCount}',
                  style: TextStyle(
                    color: n.isUser ? NMColors.green : NMColors.muted,
                    fontSize: 12,
                    fontWeight: n.isUser ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// ACTIVITY BAR
// =============================================================================

class _ActivityBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = [
      2,
      0,
      1,
      3,
      0,
      0,
      4,
      2,
      1,
      0,
      5,
      3,
      2,
      1,
      0,
      4,
      6,
      2,
      0,
      1,
      3,
      4,
      0,
      2,
      5,
      3,
      1,
      0,
      4,
      2,
    ];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.map((v) {
              final heightFraction = maxVal > 0 ? v / maxVal : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    height: 48 * heightFraction + 2,
                    decoration: BoxDecoration(
                      color: v == 0
                          ? NMColors.border
                          : NMColors.green.withOpacity(
                              0.3 + 0.7 * heightFraction,
                            ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                '30 days ago',
                style: TextStyle(color: NMColors.muted, fontSize: 10),
              ),
              Spacer(),
              Text(
                'Today',
                style: TextStyle(color: NMColors.muted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: NMColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
