import 'package:flutter/material.dart';
import '../main.dart';

// ── Badge model ───────────────────────────────────────────────────────────────
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

// ── Neighborhood model ────────────────────────────────────────────────────────
class _Neighborhood {
  final String name;
  final int reportCount;
  final bool isUser;

  const _Neighborhood(this.name, this.reportCount, {this.isUser = false});
}

const _leaderboard = [
  _Neighborhood('Bab Bhar', 143),
  _Neighborhood('Lac 2', 103),
  _Neighborhood('Médina', 79, isUser: true),
  _Neighborhood('Tunis Centre', 61),
  _Neighborhood('La Marsa', 44),
];

// ── Profile page ──────────────────────────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Avatar + name ────────────────────────────────────────────────
          _ProfileHero(),
          const SizedBox(height: 16),

          // ── Stat cards ───────────────────────────────────────────────────
          _StatGrid(),
          const SizedBox(height: 20),

          // ── Badges ───────────────────────────────────────────────────────
          const _SectionHeader('Badges'),
          const SizedBox(height: 10),
          _BadgeGrid(),
          const SizedBox(height: 20),

          // ── Neighborhood leaderboard ──────────────────────────────────────
          const _SectionHeader('Neighborhood leaderboard'),
          const SizedBox(height: 10),
          _Leaderboard(),
          const SizedBox(height: 20),

          // ── Activity chart placeholder ────────────────────────────────────
          const _SectionHeader('Activity · last 30 days'),
          const SizedBox(height: 10),
          _ActivityBar(),
        ],
      ),
    );
  }
}

// ── Profile hero ──────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
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
          child: const Center(
            child: Text(
              'KM',
              style: TextStyle(
                color: NMColors.green,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Karim M.',
                style: TextStyle(
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
                  const Text(
                    'Tunis · Joined Jan 2025',
                    style: TextStyle(color: NMColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat grid ─────────────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '47', label: 'Reports'),
        const SizedBox(width: 8),
        _StatCard(value: '3', label: 'Neighborhoods'),
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

// ── Badge grid ────────────────────────────────────────────────────────────────
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

// ── Leaderboard ───────────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                // Rank number
                SizedBox(
                  width: 20,
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
                // Name
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
                // Bar
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
                // Count
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

// ── Activity bar (placeholder) ────────────────────────────────────────────────
class _ActivityBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 30 fake daily values
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
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: values.map((v) {
                    final heightFraction = maxVal > 0 ? v / maxVal : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        width: 7,
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
                    );
                  }).toList(),
                ),
              ),
            ],
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

// ── Section header ────────────────────────────────────────────────────────────
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
