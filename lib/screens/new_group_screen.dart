import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/turn/turn_engine.dart';
import '../providers/turn_provider.dart';
import 'turn_screen.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _person = TextEditingController();
  GroupKind _kind = GroupKind.food;
  final List<String> _people = [];

  @override
  void dispose() {
    _name.dispose();
    _person.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _person.text.trim();
    if (name.isEmpty) return;
    if (_people.any((item) => item.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That name is already in the group.')));
      return;
    }
    if (_people.length >= 24) return;
    setState(() {
      _people.add(name);
      _person.clear();
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a group name.')));
      return;
    }
    if (_people.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least 2 people.')));
      return;
    }
    final turns = context.read<TurnProvider>();
    await turns.createGroup(name: _name.text, kind: _kind, people: _people);
    if (!mounted) return;
    final created = turns.groups.first;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TurnScreen(groupId: created.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
          title: const Text('New group',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text('Group name',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('group-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Lunch run',
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Kind', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in GroupKind.values)
                  ChoiceChip(
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Members',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('new-person'),
                    controller: _person,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('add-person'),
                  onPressed: _addPerson,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_people.isEmpty)
              Text('Add at least 2 people.',
                  style: TextStyle(color: scheme.onSurfaceVariant))
            else
              for (final name in _people)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: IconButton(
                    onPressed: () => setState(() => _people.remove(name)),
                    icon: const Icon(Icons.close),
                  ),
                ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('save-group'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Create group',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
