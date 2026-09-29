import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/country.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TriviaViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  List<Country> _allCountries = [];
  List<Country> _unsolvedCountries = [];
  List<Country> _options = [];
  Country? _correctCountry;
  int _score = 0;
  int _attempts = 0;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  String _feedbackMessage = '';
  bool _isLoading = true;
  bool _gameComplete = false;
  String? _errorMessage;

  static const List<int> _pointsPerAttempt = [10, 8, 5];
  static const int _maxAttempts = 3;

  TriviaViewModel({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  List<Country> get options => _options;
  Country? get correctCountry => _correctCountry;
  int get score => _score;
  int get attempts => _attempts;
  bool get hasAnswered => _hasAnswered;
  String? get selectedAnswer => _selectedAnswer;
  String get feedbackMessage => _feedbackMessage;
  bool get isLoading => _isLoading;
  bool get gameComplete => _gameComplete;
  String? get errorMessage => _errorMessage;
  int get totalCountries => _allCountries.length;
  int get solvedCount => _allCountries.length - _unsolvedCountries.length;

  Future<void> loadGame() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _score = await _storageService.loadScore();
      final solvedFlags = await _storageService.loadSolvedFlags();

      _allCountries = await _apiService.fetchCountries();

      if (_allCountries.length < 4) {
        _errorMessage = 'Not enough countries to start the game.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _unsolvedCountries = _allCountries
          .where((c) => !solvedFlags.contains(c.iso2))
          .toList();

      if (_unsolvedCountries.isEmpty) {
        _gameComplete = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _generateQuestion();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load game: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectAnswer(String countryName) async {
    if (_hasAnswered || _correctCountry == null) return;

    _selectedAnswer = countryName;
    _attempts++;

    if (countryName == _correctCountry!.name) {
      final points = _pointsPerAttempt[_attempts - 1];
      _score += points;
      _hasAnswered = true;
      _feedbackMessage = 'Correct! +$points points';

      _unsolvedCountries.remove(_correctCountry);
      await _persistState();
    } else if (_attempts >= _maxAttempts) {
      _hasAnswered = true;
      _feedbackMessage =
          'Out of attempts! The answer is ${_correctCountry!.name}';

      _unsolvedCountries.remove(_correctCountry);
      await _persistState();
    } else {
      final remaining = _maxAttempts - _attempts;
      _feedbackMessage =
          'Wrong! $remaining attempt${remaining == 1 ? '' : 's'} remaining';
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (_unsolvedCountries.isEmpty) {
      _gameComplete = true;
      notifyListeners();
      return;
    }

    _generateQuestion();
    notifyListeners();
  }

  Future<void> resetGame() async {
    await _storageService.clearAll();
    _score = 0;
    _gameComplete = false;
    _unsolvedCountries = List.from(_allCountries);
    _generateQuestion();
    notifyListeners();
  }

  void _generateQuestion() {
    if (_unsolvedCountries.length < 4) {
      _options = List.from(_unsolvedCountries)..shuffle(Random());
    } else {
      final random = Random();
      _options = List.from(_unsolvedCountries)..shuffle(random);
      _options = _options.take(4).toList();
    }

    _correctCountry = _options[0];
    _options.shuffle(Random());

    _attempts = 0;
    _hasAnswered = false;
    _selectedAnswer = null;
    _feedbackMessage = '';
  }

  Future<void> _persistState() async {
    await _storageService.saveScore(_score);
    final solvedFlags = _allCountries
        .where((c) => !_unsolvedCountries.contains(c))
        .map((c) => c.iso2)
        .toList();
    await _storageService.saveSolvedFlags(solvedFlags);
  }
}
