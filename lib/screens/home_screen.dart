import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/turn/turn_engine.dart';
import '../providers/turn_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/person_badge.dart';
import 'history_screen.dart';
import 'home/settings_screen.dart';
import 'new_group_screen.dart';
import 'turn_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      extendBody: false,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 12, 0),
              child: SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('FairTurn',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CoinBalanceChip(variant: CoinChipVariant.header),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _GroupsPage(),
                  HistoryScreen(),
                  SettingsScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TurnNav(
        index: _tab,
        onSelected: (index) => setState(() => _tab = index),
      ),
    );
  }
}

class _GroupsPage extends StatelessWidget {
  const _GroupsPage();

  @override
  Widget build(BuildContext context) {
    final turns = context.watch<TurnProvider>();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text('Your groups',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      height: 1.05,
                      letterSpacing: -0.6)),
            ),
            Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('add-group'),
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewGroupScreen()),
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.add, color: scheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Take turns, skip the debate',
            style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        const SizedBox(height: 18),
        if (turns.groups.isEmpty)
          Text(
              'No groups yet. Start one for food runs, duty, driving, or meeting prep.',
              style: TextStyle(color: scheme.onSurfaceVariant))
        else
          for (final group in turns.groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GroupCard(group: group),
            ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TurnGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinted = group.kind == GroupKind.food;
    final fill = tinted
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.34), scheme.surface)
        : scheme.surface;
    final shown = group.people.length > 6 ? 6 : group.people.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17191C).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          key: Key('group-${group.id}'),
          borderRadius: BorderRadius.circular(26),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TurnScreen(groupId: group.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tinted
                            ? scheme.surface.withValues(alpha: 0.72)
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_icon(group.kind),
                          color: scheme.onSurface, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                              '${group.people.length} ${group.people.length == 1 ? 'member' : 'members'}',
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: SizedBox(
                      height: 32,
                      width: shown == 0 ? 0.0 : 30.0 + (shown - 1) * 18,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var i = 0; i < shown; i++)
                            Positioned(
                              left: i * 18,
                              child: PersonBadge(
                                initial: group.people[i].initial,
                                color: group.people[i].color,
                                size: 30,
                                ring: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(GroupKind kind) => switch (kind) {
        GroupKind.food => Icons.restaurant,
        GroupKind.drive => Icons.directions_car_outlined,
        GroupKind.meeting => Icons.work_outline,
        GroupKind.duty => Icons.event_available_outlined,
        GroupKind.custom => Icons.groups_outlined,
      };
}

class _TurnNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const _TurnNav({required this.index, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 68,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        indicatorColor: scheme.onSurface.withValues(alpha: 0.06),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: index,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
