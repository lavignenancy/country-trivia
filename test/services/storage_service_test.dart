import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
  });

  group('StorageService', () {
    test('loadScore returns 0 when no value stored', () async {
      final score = await storageService.loadScore();
      expect(score, 0);
    });

    test('saveScore and loadScore roundtrip', () async {
      await storageService.saveScore(42);
      final score = await storageService.loadScore();
      expect(score, 42);
    });

    test('saveScore overwrites previous value', () async {
      await storageService.saveScore(10);
      await storageService.saveScore(99);
      final score = await storageService.loadScore();
      expect(score, 99);
    });

    test('loadSolvedFlags returns empty list when none stored', () async {
      final flags = await storageService.loadSolvedFlags();
      expect(flags, isEmpty);
    });

    test('saveSolvedFlags and loadSolvedFlags roundtrip', () async {
      await storageService.saveSolvedFlags(['DE', 'FR', 'US']);
      final flags = await storageService.loadSolvedFlags();
      expect(flags, ['DE', 'FR', 'US']);
    });

    test('saveSolvedFlags overwrites previous value', () async {
      await storageService.saveSolvedFlags(['DE']);
      await storageService.saveSolvedFlags(['FR', 'JP']);
      final flags = await storageService.loadSolvedFlags();
      expect(flags, ['FR', 'JP']);
    });

    test('clearAll removes score and solved flags', () async {
      await storageService.saveScore(100);
      await storageService.saveSolvedFlags(['DE', 'FR']);

      await storageService.clearAll();

      final score = await storageService.loadScore();
      final flags = await storageService.loadSolvedFlags();
      expect(score, 0);
      expect(flags, isEmpty);
    });

    test('clearAll on empty storage does not throw', () async {
      expect(() => storageService.clearAll(), returnsNormally);
    });
  });
}
