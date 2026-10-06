import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';
import '../core/turn/turn_engine.dart';

class TurnProvider extends ChangeNotifier {
  static const _key = 'ft_turns';

  List<TurnGroup> groups = [];
  List<Assignment> history = [];
  final Map<String, Set<String>> absent = {};
  final Map<String, Set<String>> _passed = {};
  var _seq = 0;

  Future<void> init() async {
    final raw = await StorageService.instance.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final book = TurnBook.decode(raw);
      groups = book.groups;
      history = book.assignments;
      absent
        ..clear()
        ..addAll({
          for (final entry in book.absent.entries)
            entry.key: entry.value.toSet(),
        });
    } catch (error) {
      debugPrint('drop saved turns: $error');
      await StorageService.instance.remove(_key);
    }
  }

  Future<void> adopt(TurnBook book) async {
    groups = book.groups;
    history = book.assignments;
    absent
      ..clear()
      ..addAll({
        for (final entry in book.absent.entries) entry.key: entry.value.toSet(),
      });
    _passed.clear();
    notifyListeners();
    await _save();
  }

  TurnGroup? groupById(String id) {
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  bool isAbsent(String groupId, String personId) =>
      absent[groupId]?.contains(personId) ?? false;

  TurnPick? suggestion(String groupId) {
    final group = groupById(groupId);
    if (group == null) return null;
    return TurnEngine.suggest(
      group: group,
      history: history,
      absentIds: absent[groupId] ?? const {},
      passedIds: _passed[groupId] ?? const {},
    );
  }

  void setAbsent(String groupId, String personId, bool value) {
    final ids = absent.putIfAbsent(groupId, () => {});
    if (value) {
      ids.add(personId);
    } else {
      ids.remove(personId);
    }
    _passed[groupId]?.remove(personId);
    notifyListeners();
    _save();
  }

  /// Moves the suggestion to the next fairest person who is still present.
  void swap(String groupId) {
    final group = groupById(groupId);
    final current = suggestion(groupId);
    if (group == null || current == null) return;
    final present =
        group.people.where((person) => !isAbsent(groupId, person.id)).length;
    if (present < 2) return;
    final passed = _passed.putIfAbsent(groupId, () => {});
    passed.add(current.person.id);
    if (suggestion(groupId) == null) {
      passed
        ..clear()
        ..add(current.person.id);
    }
    notifyListeners();
  }

  Future<void> skip(String groupId, String reason) async {
    final current = suggestion(groupId);
    if (current == null) return;
    history.insert(
      0,
      Assignment(
        id: _nextId('skip'),
        groupId: groupId,
        personId: current.person.id,
        atMillis: DateTime.now().millisecondsSinceEpoch,
        kind: AssignmentKind.skipped,
        reason: reason.trim(),
      ),
    );
    swap(groupId);
    notifyListeners();
    await _save();
  }

  Future<void> confirm(String groupId) async {
    final current = suggestion(groupId);
    if (current == null) return;
    history.insert(
      0,
      Assignment(
        id: _nextId('turn'),
        groupId: groupId,
        personId: current.person.id,
        atMillis: DateTime.now().millisecondsSinceEpoch,
        kind: AssignmentKind.completed,
        reason: current.reason,
      ),
    );
    _passed.remove(groupId);
    notifyListeners();
    await _save();
  }

  Future<void> createGroup({
    required String name,
    required GroupKind kind,
    required List<String> people,
  }) async {
    final id = _nextId('group');
    groups = [
      TurnGroup(
        id: id,
        name: name.trim(),
        kind: kind,
        people: [
          for (var i = 0; i < people.length; i++)
            Person(id: _nextId('person'), name: people[i].trim(), color: i),
        ],
      ),
      ...groups,
    ];
    notifyListeners();
    await _save();
  }

  Future<void> addPerson(String groupId, String name) async {
    final group = groupById(groupId);
    if (group == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (group.people
        .any((person) => person.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final next = TurnGroup(
      id: group.id,
      name: group.name,
      kind: group.kind,
      people: [
        ...group.people,
        Person(
            id: _nextId('person'), name: trimmed, color: group.people.length),
      ],
    );
    groups = [for (final item in groups) item.id == groupId ? next : item];
    notifyListeners();
    await _save();
  }

  Future<void> deleteGroup(String groupId) async {
    groups = groups.where((group) => group.id != groupId).toList();
    history = history.where((item) => item.groupId != groupId).toList();
    absent.remove(groupId);
    _passed.remove(groupId);
    notifyListeners();
    await _save();
  }

  List<Assignment> historyOf(String? groupId) {
    final items = groupId == null
        ? history
        : history.where((item) => item.groupId == groupId).toList();
    return [...items]..sort((a, b) => b.atMillis.compareTo(a.atMillis));
  }

  String _nextId(String prefix) {
    _seq += 1;
    final salt = Random().nextInt(0xFFFFFF).toRadixString(16);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$salt-$_seq';
  }

  Future<void> _save() async {
    final book = TurnBook(
      groups: groups,
      assignments: history,
      absent: {
        for (final entry in absent.entries) entry.key: entry.value.toList()
      },
    );
    await StorageService.instance.saveString(_key, book.encode());
  }
}
