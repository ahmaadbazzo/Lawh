import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lawh/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daily goal defaults to ten and is clamped to supported range', () async {
    final storage = StorageService();
    await storage.init();

    expect(storage.getDailyGoal(), 10);
    await storage.setDailyGoal(900);
    expect(storage.getDailyGoal(), 500);
    await storage.setDailyGoal(0);
    expect(storage.getDailyGoal(), 1);
  });

  test('rapid answer writes do not lose total or daily counts', () async {
    final storage = StorageService();
    await storage.init();

    await Future.wait(
      List.generate(
        24,
        (index) => storage.recordAnswer(isCorrect: index.isEven),
      ),
    );

    expect(storage.getTotalTested(), 24);
    expect(storage.getTotalCorrect(), 12);
    expect(storage.getDailyCompleted(), 24);
    expect(storage.getStreak(), 1);
  });
}
