import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/turn/turn_engine.dart';
import '../providers/turn_provider.dart';
import '../widgets/person_badge.dart';
import 'history_screen.dart';

class TurnScreen extends StatelessWidget {
  final String groupId;

  const TurnScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final turns = context.watch<TurnProvider>();
    final group = turns.groupById(groupId);
    if (group == null) {
      return const Scaffold(body: Center(child: Text('This group is gone.')));
    }
    final scheme = Theme.of(context).colorScheme;
    final pick = turns.suggestion(groupId);
    final presentCount = group.people
        .where((person) => !turns.isAbsent(groupId, person.id))
        .length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            _PageHeader(
              onBack: () => Navigator.of(context).pop(),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _menu(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'history', child: Text('History')),
                  PopupMenuItem(value: 'add', child: Text('Add person')),
                  PopupMenuItem(value: 'delete', child: Text('Delete group')),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_kindIcon(group.kind),
                            size: 16, color: scheme.onSurface),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                      ),
                    ],
                  ),
                  Text(
                      '${group.people.length} ${group.people.length == 1 ? 'member' : 'members'}',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Next turn',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface)),
            const SizedBox(height: 12),
            if (pick == null)
              Text('Nobody is here. Mark someone present to pick a turn.',
                  style: TextStyle(color: scheme.onSurfaceVariant))
            else
              _SuggestionCard(pick: pick, scheme: scheme),
            const SizedBox(height: 22),
            Text('Here today',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: scheme.onSurface)),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final person in group.people)
                          _Presence(
                            person: person,
                            absent: turns.isAbsent(groupId, person.id),
                            onTap: () => turns.setAbsent(groupId, person.id,
                                !turns.isAbsent(groupId, person.id)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const Key('confirm-turn'),
                onPressed: pick == null
                    ? null
                    : () async {
                        final name = pick.person.name;
                        await context.read<TurnProvider>().confirm(groupId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Recorded $name's turn.")),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Confirm turn',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: presentCount < 2 ? null : () => turns.swap(groupId),
                style: OutlinedButton.styleFrom(
                  backgroundColor: scheme.surface,
                  side:
                      BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.sync),
                label: const Text('Swap',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: pick == null || presentCount < 2
                  ? null
                  : () => _skip(context, pick.person.name),
              child: Text('Skip and add a reason',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String value) async {
    final turns = context.read<TurnProvider>();
    if (value == 'history') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HistoryScreen(groupId: groupId),
      ));
      return;
    }
    if (value == 'add') {
      final name = await _askName(context);
      if (name == null || !context.mounted) return;
      await turns.addPerson(groupId, name);
      return;
    }
    if (!context.mounted) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this group?'),
        content:
            const Text("This group's turns will be deleted on this device."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    await turns.deleteGroup(groupId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _skip(BuildContext context, String name) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReasonSheet(name: name),
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    await context.read<TurnProvider>().skip(groupId, reason.trim());
  }

  IconData _kindIcon(GroupKind kind) => switch (kind) {
        GroupKind.food => Icons.restaurant,
        GroupKind.drive => Icons.directions_car_outlined,
        GroupKind.meeting => Icons.work_outline,
        GroupKind.duty => Icons.event_available_outlined,
        GroupKind.custom => Icons.groups_outlined,
      };

  Future<String?> _askName(BuildContext context) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          const _NameSheet(title: 'Add person', action: 'Add'),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Widget child;
  final Widget? trailing;

  const _PageHeader({required this.onBack, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        Expanded(child: child),
        trailing ?? const SizedBox(width: 48),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final TurnPick pick;
  final ColorScheme scheme;

  const _SuggestionCard({required this.pick, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.45), scheme.surface),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: PersonBadge(
                initial: pick.person.initial,
                color: pick.person.color,
                size: 76),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Suggested',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(pick.person.name,
                    key: const Key('suggested-name'),
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text(pick.reason,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Presence extends StatelessWidget {
  final Person person;
  final bool absent;
  final VoidCallback onTap;

  const _Presence(
      {required this.person, required this.absent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            PersonBadge(
              initial: person.initial,
              color: person.color,
              size: 58,
              dashed: absent,
              checked: !absent,
              crossed: absent,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 16,
              child: Text(absent ? 'Away' : '',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonSheet extends StatefulWidget {
  final String name;

  const _ReasonSheet({required this.name});

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.name} skips',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'This turn is not counted. The next person is chosen by how many turns they already took.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('skip-reason'),
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Busy, away on a trip...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('confirm-skip'),
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('Save reason'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameSheet extends StatefulWidget {
  final String title;
  final String action;

  const _NameSheet({required this.title, required this.action});

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            key: const Key('person-name'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('confirm-person'),
              onPressed: () => Navigator.pop(context, _controller.text),
              child: Text(widget.action),
            ),
          ),
        ],
      ),
    );
  }
}
