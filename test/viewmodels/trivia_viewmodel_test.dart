import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/services/api_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/trivia_viewmodel.dart';

class FakeApiService extends ApiService {
  final List<Country> countriesToReturn;
  final bool shouldThrow;

  FakeApiService({
    required this.countriesToReturn,
    this.shouldThrow = false,
  });

  @override
  Future<List<Country>> fetchCountries() async {
    if (shouldThrow) throw Exception('Network error');
    return countriesToReturn;
  }
}

class FakeStorageService extends StorageService {
  int _score = 0;
  List<String> _solvedFlags = [];

  @override
  Future<int> loadScore() async => _score;

  @override
  Future<void> saveScore(int score) async {
    _score = score;
  }

  @override
  Future<List<String>> loadSolvedFlags() async => _solvedFlags;

  @override
  Future<void> saveSolvedFlags(List<String> solvedFlags) async {
    _solvedFlags = solvedFlags;
  }

  @override
  Future<void> clearAll() async {
    _score = 0;
    _solvedFlags = [];
  }
}

void main() {
  late FakeApiService apiService;
  late FakeStorageService storageService;
  late TriviaViewModel viewModel;

  final testCountries = List.generate(
    10,
    (i) => Country(
      name: 'Country $i',
      flagUrl: 'https://flagcdn.com/w320/c$i.png',
      iso2: 'C$i',
      iso3: 'C0$i',
    ),
  );

  setUp(() {
    apiService = FakeApiService(countriesToReturn: testCountries);
    storageService = FakeStorageService();
    viewModel = TriviaViewModel(
      apiService: apiService,
      storageService: storageService,
    );
  });

  group('TriviaViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.isLoading, true);
      expect(viewModel.score, 0);
      expect(viewModel.attempts, 0);
      expect(viewModel.hasAnswered, false);
      expect(viewModel.gameComplete, false);
      expect(viewModel.options, isEmpty);
      expect(viewModel.correctCountry, isNull);
    });

    test('loadGame sets loading false and generates question', () async {
      await viewModel.loadGame();

      expect(viewModel.isLoading, false);
      expect(viewModel.options.length, 4);
      expect(viewModel.correctCountry, isNotNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadGame sets error when API fails', () async {
      final failingService = FakeApiService(
        countriesToReturn: [],
        shouldThrow: true,
      );
      final vm = TriviaViewModel(
        apiService: failingService,
        storageService: storageService,
      );

      await vm.loadGame();

      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNotNull);
      expect(vm.errorMessage, contains('Network error'));
    });

    test('loadGame sets error when fewer than 4 countries', () async {
      final fewCountries = testCountries.take(2).toList();
      final smallService = FakeApiService(countriesToReturn: fewCountries);
      final vm = TriviaViewModel(
        apiService: smallService,
        storageService: storageService,
      );

      await vm.loadGame();

      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNotNull);
    });

    test('correct answer on first attempt awards 10 points', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      viewModel.selectAnswer(correctName);

      expect(viewModel.score, 10);
      expect(viewModel.hasAnswered, true);
      expect(viewModel.feedbackMessage, contains('Correct'));
      expect(viewModel.feedbackMessage, contains('+10'));
    });

    test('correct answer on second attempt awards 8 points', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      final wrongOptions = viewModel.options
          .where((c) => c.name != correctName)
          .toList();

      viewModel.selectAnswer(wrongOptions[0].name);
      expect(viewModel.hasAnswered, false);
      expect(viewModel.attempts, 1);

      viewModel.selectAnswer(correctName);
      expect(viewModel.score, 8);
      expect(viewModel.hasAnswered, true);
      expect(viewModel.feedbackMessage, contains('+8'));
    });

    test('correct answer on third attempt awards 5 points', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      final wrongOptions = viewModel.options
          .where((c) => c.name != correctName)
          .toList();

      viewModel.selectAnswer(wrongOptions[0].name);
      viewModel.selectAnswer(wrongOptions[1].name);
      expect(viewModel.hasAnswered, false);
      expect(viewModel.attempts, 2);

      viewModel.selectAnswer(correctName);
      expect(viewModel.score, 5);
      expect(viewModel.hasAnswered, true);
      expect(viewModel.feedbackMessage, contains('+5'));
    });

    test('three wrong answers reveals correct answer with 0 points', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      final wrongOptions = viewModel.options
          .where((c) => c.name != correctName)
          .toList();

      viewModel.selectAnswer(wrongOptions[0].name);
      viewModel.selectAnswer(wrongOptions[1].name);
      viewModel.selectAnswer(wrongOptions[2].name);

      expect(viewModel.score, 0);
      expect(viewModel.hasAnswered, true);
      expect(viewModel.feedbackMessage, contains('Out of attempts'));
      expect(viewModel.feedbackMessage, contains(correctName));
    });

    test('selectAnswer does nothing after hasAnswered is true', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      viewModel.selectAnswer(correctName);
      expect(viewModel.score, 10);

      viewModel.selectAnswer('Something else');
      expect(viewModel.score, 10);
      expect(viewModel.attempts, 1);
    });

    test('nextQuestion generates new question', () async {
      await viewModel.loadGame();

      final firstCorrect = viewModel.correctCountry;
      viewModel.selectAnswer(firstCorrect!.name);
      viewModel.nextQuestion();

      expect(viewModel.hasAnswered, false);
      expect(viewModel.attempts, 0);
      expect(viewModel.feedbackMessage, isEmpty);
    });

    test('solved countries are excluded from future questions', () async {
      await viewModel.loadGame();

      final firstCorrect = viewModel.correctCountry!;
      viewModel.selectAnswer(firstCorrect.name);
      viewModel.nextQuestion();

      // The previously solved country should not appear in options
      final optionNames = viewModel.options.map((c) => c.name).toList();
      expect(optionNames, isNot(contains(firstCorrect.name)));
    });

    test('game completes when all countries are solved', () async {
      // Pre-solve all but one country so solving the last one completes the game
      final fourCountries = testCountries.take(4).toList();
      final preSolved = fourCountries.take(3).map((c) => c.iso2).toList();
      await storageService.saveSolvedFlags(preSolved);

      final smallService = FakeApiService(countriesToReturn: fourCountries);
      final vm = TriviaViewModel(
        apiService: smallService,
        storageService: storageService,
      );

      await vm.loadGame();
      expect(vm.gameComplete, false);

      final correctName = vm.correctCountry!.name;
      vm.selectAnswer(correctName);
      vm.nextQuestion();

      expect(vm.gameComplete, true);
    });

    test('resetGame clears score and marks game incomplete', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      viewModel.selectAnswer(correctName);
      expect(viewModel.score, 10);

      await viewModel.resetGame();

      expect(viewModel.score, 0);
      expect(viewModel.gameComplete, false);
      expect(viewModel.hasAnswered, false);
      expect(viewModel.options.length, 4);
    });

    test('progress tracking: solvedCount and totalCountries', () async {
      await viewModel.loadGame();

      expect(viewModel.totalCountries, 10);
      expect(viewModel.solvedCount, 0);

      final correctName = viewModel.correctCountry!.name;
      viewModel.selectAnswer(correctName);

      expect(viewModel.solvedCount, 1);
    });

    test('persists score to storage service', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      viewModel.selectAnswer(correctName);

      final persistedScore = await storageService.loadScore();
      expect(persistedScore, 10);
    });

    test('persists solved flags to storage service', () async {
      await viewModel.loadGame();

      final correctCountry = viewModel.correctCountry!;
      await viewModel.selectAnswer(correctCountry.name);

      final persistedFlags = await storageService.loadSolvedFlags();
      expect(persistedFlags, contains(correctCountry.iso2));
      expect(persistedFlags.length, 1);
    });

    test('loadGame restores solved flags from storage', () async {
      await storageService.saveSolvedFlags(['C0', 'C1', 'C2']);

      await viewModel.loadGame();

      // Solved countries should not appear in options
      final optionNames = viewModel.options.map((c) => c.name).toList();
      expect(optionNames, isNot(contains('Country 0')));
      expect(optionNames, isNot(contains('Country 1')));
      expect(optionNames, isNot(contains('Country 2')));
    });

    test('loadGame restores score from storage', () async {
      await storageService.saveScore(50);

      await viewModel.loadGame();

      expect(viewModel.score, 50);
    });

    test('loadGame sets gameComplete when all countries pre-solved', () async {
      // Pre-solve all countries
      final allIso2 = testCountries.map((c) => c.iso2).toList();
      await storageService.saveSolvedFlags(allIso2);

      await viewModel.loadGame();

      expect(viewModel.gameComplete, true);
      expect(viewModel.isLoading, false);
    });

    test('wrong answer feedback shows remaining attempts', () async {
      await viewModel.loadGame();

      final correctName = viewModel.correctCountry!.name;
      final wrongOptions = viewModel.options
          .where((c) => c.name != correctName)
          .toList();

      viewModel.selectAnswer(wrongOptions[0].name);
      expect(viewModel.feedbackMessage, contains('2 attempts remaining'));

      viewModel.selectAnswer(wrongOptions[1].name);
      expect(viewModel.feedbackMessage, contains('1 attempt remaining'));
    });
  });
}
