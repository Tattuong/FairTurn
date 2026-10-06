import 'turn_engine.dart';

class DemoSeed {
  DemoSeed._();

  static int _day(int month, int day) =>
      DateTime(2026, month, day, 12).millisecondsSinceEpoch;

  static TurnBook book() {
    const lunch = TurnGroup(
      id: 'lunch',
      name: 'Lunch run',
      kind: GroupKind.food,
      people: [
        Person(id: 'linh', name: 'Lena', color: 0),
        Person(id: 'nam', name: 'Nate', color: 1),
        Person(id: 'mai', name: 'Maya', color: 2),
        Person(id: 'an', name: 'Alex', color: 3),
      ],
    );
    const drive = TurnGroup(
      id: 'drive',
      name: 'Weekend driving',
      kind: GroupKind.drive,
      people: [
        Person(id: 'tuan', name: 'Theo', color: 1),
        Person(id: 'khoa', name: 'Kai', color: 4),
        Person(id: 'ha', name: 'Hanna', color: 5),
      ],
    );
    const meeting = TurnGroup(
      id: 'meeting',
      name: 'Meeting prep',
      kind: GroupKind.meeting,
      people: [
        Person(id: 'phuong', name: 'Priya', color: 0),
        Person(id: 'quyen', name: 'Quinn', color: 1),
        Person(id: 'hieu', name: 'Henry', color: 2),
        Person(id: 'dang', name: 'Drew', color: 5),
        Person(id: 'nga', name: 'Nina', color: 4),
      ],
    );
    Assignment done(String id, String personId, int month, int day) =>
        Assignment(
          id: id,
          groupId: lunch.id,
          personId: personId,
          atMillis: _day(month, day),
          kind: AssignmentKind.completed,
          reason: TurnEngine.fewestReason,
        );
    return TurnBook(
      groups: const [lunch, drive, meeting],
      assignments: [
        done('l1', 'linh', 3, 2),
        done('l2', 'linh', 3, 20),
        done('n1', 'nam', 3, 5),
        done('n2', 'nam', 3, 28),
        done('n3', 'nam', 4, 10),
        done('m1', 'mai', 3, 8),
        done('m2', 'mai', 3, 30),
        done('m3', 'mai', 4, 12),
        done('a1', 'an', 3, 3),
        done('a2', 'an', 3, 18),
      ],
      absent: const {
        'lunch': ['an'],
      },
    );
  }
}
