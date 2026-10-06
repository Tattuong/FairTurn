import 'package:fairturn/core/turn/demo_seed.dart';
import 'package:fairturn/core/turn/turn_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the lunch demo suggests Lena because Alex is absent', () {
    final book = DemoSeed.book();
    final lunch = book.groups.first;
    final pick = TurnEngine.suggest(
      group: lunch,
      history: book.assignments,
      absentIds: book.absent['lunch']!.toSet(),
    );
    expect(pick?.person.name, 'Lena');
    expect(pick?.reason, TurnEngine.fewestReason);
    expect(TurnEngine.completedCount(book.assignments, 'lunch', 'linh'), 2);
    expect(TurnEngine.completedCount(book.assignments, 'lunch', 'nam'), 3);
    expect(TurnEngine.completedCount(book.assignments, 'lunch', 'mai'), 3);
    expect(TurnEngine.completedCount(book.assignments, 'lunch', 'an'), 2);
    expect(
        TurnEngine.formatTurnDate(DateTime(2026, 4, 12).millisecondsSinceEpoch),
        'Apr 12');
  });

  test('a tie goes to the person who waited longest', () {
    final book = DemoSeed.book();
    final lunch = book.groups.first;
    final pick = TurnEngine.suggest(
      group: lunch,
      history: book.assignments,
      absentIds: const {},
    );
    expect(pick?.person.name, 'Alex');
    expect(pick?.reason, TurnEngine.oldestReason);
  });

  test('passing the leader reveals the next fairest person', () {
    final book = DemoSeed.book();
    final lunch = book.groups.first;
    final pick = TurnEngine.suggest(
      group: lunch,
      history: book.assignments,
      absentIds: book.absent['lunch']!.toSet(),
      passedIds: const {'linh'},
    );
    expect(pick?.person.name, 'Nate');
    expect(pick?.reason, TurnEngine.oldestReason);
  });

  test('a skipped turn is not counted', () {
    final book = DemoSeed.book();
    final history = [
      ...book.assignments,
      Assignment(
        id: 'skip',
        groupId: 'lunch',
        personId: 'linh',
        atMillis: DateTime(2026, 4, 20).millisecondsSinceEpoch,
        kind: AssignmentKind.skipped,
        reason: 'Busy',
      ),
    ];
    expect(TurnEngine.completedCount(history, 'lunch', 'linh'), 2);
  });

  test('the saved book round-trips', () {
    final again = TurnBook.decode(DemoSeed.book().encode());
    expect(again.groups, hasLength(3));
    expect(again.absent['lunch'], ['an']);
    expect(again.assignments, hasLength(10));
  });
}
