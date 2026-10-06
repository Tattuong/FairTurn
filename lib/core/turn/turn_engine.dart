import 'dart:convert';

enum GroupKind { food, drive, meeting, duty, custom }

extension GroupKindLabel on GroupKind {
  String get label => switch (this) {
        GroupKind.food => 'Food run',
        GroupKind.drive => 'Driving',
        GroupKind.meeting => 'Meeting prep',
        GroupKind.duty => 'Duty',
        GroupKind.custom => 'Other',
      };
}

class Person {
  final String id;
  final String name;
  final int color;

  const Person({required this.id, required this.name, required this.color});

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        color: (json['color'] as num?)?.toInt() ?? 0,
      );
}

class TurnGroup {
  final String id;
  final String name;
  final GroupKind kind;
  final List<Person> people;

  const TurnGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.people,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'people': people.map((person) => person.toJson()).toList(),
      };

  factory TurnGroup.fromJson(Map<String, dynamic> json) => TurnGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: GroupKind.values.byName(json['kind'] as String? ?? 'custom'),
        people: (json['people'] as List)
            .map((item) =>
                Person.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

enum AssignmentKind { completed, skipped }

class Assignment {
  final String id;
  final String groupId;
  final String personId;
  final int atMillis;
  final AssignmentKind kind;
  final String reason;

  const Assignment({
    required this.id,
    required this.groupId,
    required this.personId,
    required this.atMillis,
    required this.kind,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'personId': personId,
        'atMillis': atMillis,
        'kind': kind.name,
        'reason': reason,
      };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        personId: json['personId'] as String,
        atMillis: (json['atMillis'] as num).toInt(),
        kind: AssignmentKind.values
            .byName(json['kind'] as String? ?? 'completed'),
        reason: json['reason'] as String? ?? '',
      );
}

class TurnPick {
  final Person person;
  final String reason;

  const TurnPick({required this.person, required this.reason});
}

class TurnEngine {
  TurnEngine._();

  static const fewestReason = 'Fewest turns among people who are here';
  static const oldestReason =
      'Longest since their last turn among people who are here';

  static int completedCount(
      List<Assignment> history, String groupId, String personId) {
    return history
        .where((item) =>
            item.groupId == groupId &&
            item.personId == personId &&
            item.kind == AssignmentKind.completed)
        .length;
  }

  static int lastCompletedAt(
      List<Assignment> history, String groupId, String personId) {
    var last = 0;
    for (final item in history) {
      if (item.groupId != groupId ||
          item.personId != personId ||
          item.kind != AssignmentKind.completed) {
        continue;
      }
      if (item.atMillis > last) last = item.atMillis;
    }
    return last;
  }

  /// Picks the present person with the fewest completed turns.
  /// A tie goes to whoever has waited longest.
  static TurnPick? suggest({
    required TurnGroup group,
    required List<Assignment> history,
    required Set<String> absentIds,
    Set<String> passedIds = const {},
  }) {
    final pool = [
      for (final person in group.people)
        if (!absentIds.contains(person.id) && !passedIds.contains(person.id))
          person,
    ];
    if (pool.isEmpty) return null;
    pool.sort((a, b) {
      final byCount = completedCount(history, group.id, a.id)
          .compareTo(completedCount(history, group.id, b.id));
      if (byCount != 0) return byCount;
      final byWait = lastCompletedAt(history, group.id, a.id)
          .compareTo(lastCompletedAt(history, group.id, b.id));
      if (byWait != 0) return byWait;
      return a.name.compareTo(b.name);
    });
    final chosen = pool.first;
    final lowest = completedCount(history, group.id, chosen.id);
    final tied = pool
        .where(
            (person) => completedCount(history, group.id, person.id) == lowest)
        .length;
    return TurnPick(
      person: chosen,
      reason: tied > 1 ? oldestReason : fewestReason,
    );
  }

  static String shareSummary({
    required TurnGroup group,
    required List<Assignment> history,
  }) {
    final buffer = StringBuffer()
      ..writeln(group.name)
      ..writeln('Assignment history')
      ..writeln();
    for (final person in group.people) {
      final count = completedCount(history, group.id, person.id);
      buffer
          .writeln('• ${person.name}: $count ${count == 1 ? 'turn' : 'turns'}');
    }
    final recent = history
        .where((item) =>
            item.groupId == group.id && item.kind == AssignmentKind.completed)
        .toList()
      ..sort((a, b) => b.atMillis.compareTo(a.atMillis));
    if (recent.isNotEmpty) {
      buffer.writeln();
      for (final item in recent.take(6)) {
        final person =
            group.people.where((p) => p.id == item.personId).firstOrNull;
        buffer.writeln(
            '• ${person?.name ?? '—'} completed · ${formatTurnDate(item.atMillis)}');
      }
    }
    return buffer.toString().trim();
  }

  static String formatTurnDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class TurnBook {
  final List<TurnGroup> groups;
  final List<Assignment> assignments;
  final Map<String, List<String>> absent;

  const TurnBook({
    required this.groups,
    required this.assignments,
    required this.absent,
  });

  Map<String, dynamic> toJson() => {
        'groups': groups.map((group) => group.toJson()).toList(),
        'assignments': assignments.map((item) => item.toJson()).toList(),
        'absent': absent,
      };

  String encode() => jsonEncode(toJson());

  factory TurnBook.decode(String raw) =>
      TurnBook.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  factory TurnBook.fromJson(Map<String, dynamic> json) => TurnBook(
        groups: (json['groups'] as List? ?? [])
            .map((item) =>
                TurnGroup.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        assignments: (json['assignments'] as List? ?? [])
            .map((item) =>
                Assignment.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        absent: {
          for (final entry in (json['absent'] as Map? ?? {}).entries)
            entry.key as String:
                (entry.value as List).map((id) => id as String).toList(),
        },
      );
}
