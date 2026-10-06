import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/turn/turn_engine.dart';
import '../providers/turn_provider.dart';
import '../widgets/person_badge.dart';

class HistoryScreen extends StatelessWidget {
  final String? groupId;

  const HistoryScreen({super.key, this.groupId});

  @override
  Widget build(BuildContext context) {
    final turns = context.watch<TurnProvider>();
    final group = groupId == null ? null : turns.groupById(groupId!);
    if (groupId != null && group == null) {
      return const Scaffold(body: Center(child: Text('This group is gone.')));
    }
    final scheme = Theme.of(context).colorScheme;
    if (group == null) {
      return _AllHistory(turns: turns, scheme: scheme);
    }
    return _GroupHistory(group: group, turns: turns, scheme: scheme);
  }
}

class _AllHistory extends StatelessWidget {
  final TurnProvider turns;
  final ColorScheme scheme;

  const _AllHistory({required this.turns, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final recent = turns.historyOf(null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('History',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: scheme.onSurface,
                height: 1.05)),
        const SizedBox(height: 6),
        Text('Turns saved on this device.',
            style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        const SizedBox(height: 18),
        if (recent.isEmpty)
          Text('No turns yet. Confirm a turn in a group to start.',
              style: TextStyle(color: scheme.onSurfaceVariant))
        else
          for (final item in recent.take(30))
            _ActivityTile(turns: turns, item: item),
      ],
    );
  }
}

class _GroupHistory extends StatelessWidget {
  final TurnGroup group;
  final TurnProvider turns;
  final ColorScheme scheme;

  const _GroupHistory(
      {required this.group, required this.turns, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final counts = [
      for (final person in group.people)
        (person, TurnEngine.completedCount(turns.history, group.id, person.id)),
    ];
    final maxCount =
        counts.fold<int>(1, (max, item) => item.$2 > max ? item.$2 : max);
    final recent = turns
        .historyOf(group.id)
        .where((item) => item.kind == AssignmentKind.completed);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assignment history',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: -0.5,
                              height: 1.05,
                              color: scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(group.name,
                          style: TextStyle(
                              fontSize: 14, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: Text('Completed turns',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: scheme.onSurface)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17191C).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (final (person, count) in counts)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            PersonBadge(
                                initial: person.initial,
                                color: person.color,
                                size: 36),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(person.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            _CountBar(
                              value: maxCount == 0 ? 0 : count / maxCount,
                              color: personColors[
                                  person.color.abs() % personColors.length],
                              track: scheme.surfaceContainerHighest,
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 16,
                              child: Text('$count',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('Recent activity',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: scheme.onSurface)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                children: [
                  for (final item in recent.take(8))
                    _ActivityTile(turns: turns, item: item, showGroup: false),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'A suggested turn is not counted until you confirm it.',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => Share.share(TurnEngine.shareSummary(
                      group: group, history: turns.history)),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share summary',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;

  const _CountBar(
      {required this.value, required this.color, required this.track});

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    return SizedBox(
      width: 96,
      height: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            if (fraction > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: ColoredBox(color: color),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final TurnProvider turns;
  final Assignment item;
  final bool showGroup;

  const _ActivityTile(
      {required this.turns, required this.item, this.showGroup = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final group = turns.groupById(item.groupId);
    Person? person;
    if (group != null) {
      for (final candidate in group.people) {
        if (candidate.id == item.personId) person = candidate;
      }
    }
    final done = item.kind == AssignmentKind.completed;
    final title = person?.name ?? '—';
    final subtitle = done
        ? 'Completed'
        : 'Skipped${item.reason.isEmpty ? '' : ' · ${item.reason}'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17191C).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            PersonBadge(
              initial: person?.initial ?? '?',
              color: person?.color ?? 3,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    !showGroup || group == null
                        ? subtitle
                        : '$subtitle · ${group.name}',
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(TurnEngine.formatTurnDate(item.atMillis),
                style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
