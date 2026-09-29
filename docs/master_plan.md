# Country Trivia App — Master Plan

## 1. Overview

A Flutter country trivia game where users guess which country a flag belongs to. The app uses **MVVM architecture** with **Provider** for state management, fetches country data from the REST Countries API, displays flags via flagcdn.com, and persists game state across sessions.

---

## 2. Architecture (MVVM + Provider)

```
lib/
├── main.dart                          # App entry, Provider setup
├── models/
│   └── country.dart                   # Country data model
├── services/
│   ├── api_service.dart               # HTTP calls to countries API
│   └── storage_service.dart           # SharedPreferences persistence
├── viewmodels/
│   └── trivia_viewmodel.dart          # Game logic & state (ChangeNotifier)
└── views/
    └── trivia_view.dart               # UI — flag, options, score, feedback
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **Model** | Plain data classes (`Country`) with JSON serialization |
| **Service** | External I/O — API calls (`ApiService`), local persistence (`StorageService`) |
| **ViewModel** | Game state, scoring logic, question generation, solved-flag tracking. Exposes state via `ChangeNotifier` |
| **View** | Stateless/Stateful widgets that observe the ViewModel via `Provider`/`Consumer`. No business logic |

---

## 3. Data Sources

### 3.1 Countries API
- **Endpoint:** `GET https://countriesnow.space/api/v0.1/countries/flag/images`
- **Response format:**
  ```json
  {
    "error": false,
    "msg": "countries and flags retrieved",
    "data": [
      {
        "name": "Afghanistan",
        "flag": "https://flagcdn.com/w320/af.png",
        "iso2": "AF",
        "iso3": "AFG"
      }
    ]
  }
  ```

### 3.2 Flag CDN
- **URL pattern:** `https://flagcdn.com/w320/{iso2_lowercase}.png`
- The API already returns flag URLs; we construct from ISO2 as fallback.

---

## 4. Game Rules

| Attempt | Points |
|---------|--------|
| 1st (correct on first try) | 10 |
| 2nd (correct on second try) | 8 |
| 3rd (correct on third try) | 5 |
| Failed all 3 attempts | 0 — correct answer revealed |

- Each question shows **1 flag + 4 country name options** (1 correct + 3 random distractors).
- After answering (correct or out of attempts), the user taps **Next Question**.
- **Solved flags are tracked** and excluded from future questions until all countries have been seen.
- When all countries are solved, the game shows a completion screen with a **Reset** button.

---

## 5. Persistence

Using `shared_preferences`:

| Key | Type | Description |
|-----|------|-------------|
| `trivia_score` | `int` | Cumulative user score |
| `trivia_solved_flags` | `List<String>` | ISO2 codes of solved countries |

- Score and solved flags are saved after every question.
- On app launch, state is restored from disk.

---

## 6. ViewModel State

```dart
class TriviaViewModel extends ChangeNotifier {
  // State
  List<Country> _allCountries;        // Full country list from API
  List<Country> _unsolvedCountries;   // Countries not yet solved
  List<Country> _options;             // 4 options for current question
  Country _correctCountry;            // The correct answer
  int _score;                         // Persisted cumulative score
  int _attempts;                      // Attempts for current question (0-3)
  bool _hasAnswered;                  // Whether current question is resolved
  String? _selectedAnswer;            // Last selected option
  String _feedbackMessage;            // Feedback text
  bool _isLoading;                    // Loading state
  bool _gameComplete;                 // All countries solved
}
```

### Key Methods
- `loadGame()` — Load persisted state, fetch countries if needed
- `selectAnswer(String name)` — Process answer, update score/attempts
- `nextQuestion()` — Generate next question from unsolved pool
- `resetGame()` — Clear solved flags, reshuffle, reset score
- `_generateQuestion()` — Pick correct country + 3 distractors, shuffle

---

## 7. UI Design

### Main Game Screen (`TriviaView`)
```
┌─────────────────────────────┐
│  Country Trivia     Score: X │  ← AppBar
├─────────────────────────────┤
│  ┌───────────────────────┐  │
│  │                       │  │
│  │      FLAG IMAGE       │  │  ← 200px height, rounded corners
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  "Which country does this   │
│   flag belong to?"          │
│                             │
│  ● ● ○  (attempt dots)      │
│                             │
│  ┌───────────────────────┐  │
│  │  Country A            │  │  ← 4 answer buttons
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Country B            │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Country C            │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Country D            │  │
│  └───────────────────────┘  │
│                             │
│  [Feedback message]         │
│                             │
│  [Next Question]            │  ← Shown after answer
└─────────────────────────────┘
```

### Game Complete Screen
```
┌─────────────────────────────┐
│  🎉 Game Complete!          │
│  Final Score: XXX           │
│  You solved all countries!  │
│  [Reset Game]               │
└─────────────────────────────┘
```

---

## 8. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  shared_preferences: ^2.2.2  # Persistence
  http: ^1.2.0              # API calls (already present)
```

---

## 9. Execution Plan

### Step 1: Add dependencies
- Add `provider` and `shared_preferences` to `pubspec.yaml`
- Run `flutter pub get`

### Step 2: Create StorageService
- `lib/services/storage_service.dart`
- Methods: `loadScore()`, `saveScore()`, `loadSolvedFlags()`, `saveSolvedFlags()`, `clearAll()`

### Step 3: Update Country model
- Ensure `fromJson` handles the API response format
- Add helper to construct flag URL from ISO2

### Step 4: Create TriviaViewModel
- `lib/viewmodels/trivia_viewmodel.dart`
- Implement all game logic, scoring, solved-flag tracking
- Persist state on every change

### Step 5: Create TriviaView
- `lib/views/trivia_view.dart`
- Build UI with `Consumer<TriviaViewModel>`
- Handle loading, game, and complete states

### Step 6: Update main.dart
- Wrap app with `ChangeNotifierProvider<TriviaViewModel>`
- Initialize ViewModel before runApp

### Step 7: Add tests
- Unit tests for ViewModel scoring logic
- Widget tests for basic UI

### Step 8: Run and verify
- `flutter analyze`
- `flutter test`
- `flutter run`

---

## 10. Ticket Breakdown

### Execution Order & Concurrency

```
Phase 1 (Sequential — foundation)
  T1 → T2 → T3

Phase 2 (Concurrent — after T3)
  T4 ∥ T5

Phase 3 (Sequential — after T4 & T5)
  T6

Phase 4 (Concurrent — after T6)
  T7 ∥ T8 ∥ T9

Phase 5 (Sequential — after T7, T8, T9)
  T10
```

---

### T1: Add Dependencies
| Field | Value |
|-------|-------|
| **Depends on** | — |
| **Concurrent with** | — |
| **Phase** | 1 |

**Tasks:**
- [ ] Add `provider: ^6.1.1` to `pubspec.yaml`
- [ ] Add `shared_preferences: ^2.2.2` to `pubspec.yaml`
- [ ] Add `cached_network_image: ^3.3.1` to `pubspec.yaml`
- [ ] Run `flutter pub get`

**Acceptance criteria:** `flutter pub get` succeeds with no errors.

---

### T2: Create StorageService
| Field | Value |
|-------|-------|
| **Depends on** | T1 |
| **Concurrent with** | — |
| **Phase** | 1 |

**Tasks:**
- [ ] Create `lib/services/storage_service.dart`
- [ ] Implement `loadScore()` / `saveScore(int)`
- [ ] Implement `loadSolvedFlags()` / `saveSolvedFlags(List<String>)`
- [ ] Implement `clearAll()`

**Acceptance criteria:** All methods read/write correct `SharedPreferences` keys.

---

### T3: Update Country Model
| Field | Value |
|-------|-------|
| **Depends on** | T1 |
| **Concurrent with** | T2 |
| **Phase** | 1 |

**Tasks:**
- [ ] Update `fromJson` to handle missing `flag` field (construct from ISO2)
- [ ] Add `==` and `hashCode` based on `iso2`
- [ ] Handle null `name` gracefully (default to `'Unknown'`)

**Acceptance criteria:** Model correctly parses all API response variants.

---

### T4: Create ApiService with DI
| Field | Value |
|-------|-------|
| **Depends on** | T3 |
| **Concurrent with** | T5 |
| **Phase** | 2 |

**Tasks:**
- [ ] Add optional `http.Client` constructor parameter
- [ ] Implement `fetchCountries()` with proper error handling
- [ ] Use injected client for HTTP calls

**Acceptance criteria:** Service can be tested with `MockClient`.

---

### T5: Create TriviaViewModel
| Field | Value |
|-------|-------|
| **Depends on** | T2, T3 |
| **Concurrent with** | T4 |
| **Phase** | 2 |

**Tasks:**
- [ ] Create `lib/viewmodels/trivia_viewmodel.dart` extending `ChangeNotifier`
- [ ] Implement `loadGame()` — restore persisted state, fetch countries
- [ ] Implement `selectAnswer(String)` — scoring (10/8/5/0), attempt tracking
- [ ] Implement `nextQuestion()` — generate from unsolved pool
- [ ] Implement `resetGame()` — clear storage, reshuffle
- [ ] Implement `_generateQuestion()` — 1 correct + 3 distractors
- [ ] Implement `_persistState()` — save score + solved flags
- [ ] Add all getters for UI consumption

**Acceptance criteria:** All game logic paths work correctly with fake services.

---

### T6: Create TriviaView UI
| Field | Value |
|-------|-------|
| **Depends on** | T4, T5 |
| **Concurrent with** | — |
| **Phase** | 3 |

**Tasks:**
- [ ] Create `lib/views/trivia_view.dart`
- [ ] Build loading state (spinner)
- [ ] Build error state (message + retry button)
- [ ] Build game complete state (trophy, final score, reset button)
- [ ] Build game body: flag image, question text, attempt dots, 4 answer buttons, feedback, next button
- [ ] Use `CachedNetworkImage` for flag display
- [ ] Wire all buttons to ViewModel methods

**Acceptance criteria:** UI renders correctly for all states; buttons trigger ViewModel.

---

### T7: Update main.dart with Provider
| Field | Value |
|-------|-------|
| **Depends on** | T5 |
| **Concurrent with** | T8, T9 |
| **Phase** | 4 |

**Tasks:**
- [ ] Wrap `MaterialApp` with `ChangeNotifierProvider<TriviaViewModel>`
- [ ] Call `loadGame()` in provider `create`
- [ ] Set `TriviaView` as home

**Acceptance criteria:** App launches and loads game state on start.

---

### T8: Write ViewModel Unit Tests
| Field | Value |
|-------|-------|
| **Depends on** | T5 |
| **Concurrent with** | T7, T9 |
| **Phase** | 4 |

**Tasks:**
- [ ] Create `test/viewmodels/trivia_viewmodel_test.dart`
- [ ] Implement `FakeApiService` and `FakeStorageService`
- [ ] Test all scoring paths (10, 8, 5, 0 points)
- [ ] Test persistence (score + solved flags saved/loaded)
- [ ] Test game completion flow
- [ ] Test reset functionality
- [ ] Test edge cases (< 4 countries, API failure)

**Acceptance criteria:** ≥ 80% coverage on `trivia_viewmodel.dart`.

---

### T9: Write Service & Model Tests
| Field | Value |
|-------|-------|
| **Depends on** | T2, T3, T4 |
| **Concurrent with** | T7, T8 |
| **Phase** | 4 |

**Tasks:**
- [ ] Create `test/models/country_test.dart` — JSON parsing, equality, fallbacks
- [ ] Create `test/services/api_service_test.dart` — success, 404, 500, headers
- [ ] Create `test/services/storage_service_test.dart` — roundtrip, overwrite, clear

**Acceptance criteria:** ≥ 80% coverage on all service and model files.

---

### T10: Integration Verification
| Field | Value |
|-------|-------|
| **Depends on** | T7, T8, T9 |
| **Concurrent with** | — |
| **Phase** | 5 |

**Tasks:**
- [ ] Run `flutter analyze` — zero issues
- [ ] Run `flutter test --coverage` — all pass, ≥ 80% on services + viewmodels
- [ ] Run `flutter run` — manual smoke test
- [ ] Verify persistence across app restart
- [ ] Verify solved flags don't repeat
- [ ] Verify game completion and reset flow

**Acceptance criteria:** All checks pass; app works end-to-end.

---

### Ticket Summary

| Ticket | Title | Depends On | Concurrent With | Phase |
|--------|-------|------------|-----------------|-------|
| T1 | Add Dependencies | — | — | 1 |
| T2 | Create StorageService | T1 | T3 | 1 |
| T3 | Update Country Model | T1 | T2 | 1 |
| T4 | Create ApiService with DI | T3 | T5 | 2 |
| T5 | Create TriviaViewModel | T2, T3 | T4 | 2 |
| T6 | Create TriviaView UI | T4, T5 | — | 3 |
| T7 | Update main.dart with Provider | T5 | T8, T9 | 4 |
| T8 | Write ViewModel Tests | T5 | T7, T9 | 4 |
| T9 | Write Service & Model Tests | T2, T3, T4 | T7, T8 | 4 |
| T10 | Integration Verification | T7, T8, T9 | — | 5 |

---

## 11. Error Handling

- **API failure:** Show error SnackBar with retry option
- **Flag image load failure:** Show placeholder icon
- **Storage failure:** Fail silently, start fresh game
- **Edge case (< 4 countries):** Show error message, disable game

---

## 11. Future Enhancements

- Difficulty levels (more/fewer options, time limits)
- Hints (region, capital, currency)
- Leaderboard
- Animations and transitions
- Sound effects
- Dark mode toggle
