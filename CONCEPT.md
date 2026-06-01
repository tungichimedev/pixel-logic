# Concept 08: Nonogram / Picross Puzzle

## 1. Overview

Nonogram (also known as Picross or Griddler) is a logic puzzle game where players fill cells in a grid based on numeric clues on each row and column — completing the puzzle reveals a pixel-art picture. This Flutter implementation targets the casual-to-enthusiast spectrum with two MVP grid sizes (5x5, 10x10) and themed picture packs (Animals, Space, with more post-launch). An algorithmic puzzle generator converts any pixel grid into a valid nonogram, enabling infinite content. The progression system, theme engine, ads, and IAP are direct ports from Cube Blast with minimal modification.

---

## 2. Core Loop

1. Player opens the app to a home screen showing pack grid, daily puzzle card, and player level.
2. Player selects a pack and chooses a puzzle (thumbnail shown as blurred pixel art preview).
3. Puzzle loads: grid fills the screen with row clues on the left and column clues on the top.
4. Player taps to fill a cell (dark), long-presses to mark an X (eliminated), or uses toggle mode (switch between fill/X mode).
5. Filled cells auto-highlight when a row/column clue is satisfied (clue number turns green, #00E676).
6. Mistake: if "error checking" is on (free players), wrong cells flash red — costs a life (3 lives per puzzle).
7. Error checking can be turned off (Pro subscribers only) for purist mode.
8. Completing the puzzle: filled cells flash → pixel art image "paints" itself in with a reveal animation → stars awarded.
9. Every 4th puzzle completion triggers an interstitial ad.
10. Daily puzzle completion records the player's completion time (personal best display in MVP; leaderboard in v1.1).

---

## 3. Grid & Mechanics

### Grid Sizes

| Size  | Puzzle Type | Clue Density | Approx. Solve Time |
|-------|-------------|--------------|---------------------|
| 5x5   | Tutorial    | Simple       | 1–2 min             |
| 10x10 | Standard    | Medium       | 5–10 min            |
| 15x15 | Advanced    | Dense        | 15–25 min (post-launch) |
| 20x20 | Expert      | Very dense   | 30–60 min (post-launch) |

### Row/Column Clues

- Each clue is a sequence of positive integers separated by spaces.
- Each number represents a contiguous run of filled cells.
- Between runs, at least one empty cell must exist.
- Example row clue `[3, 1, 2]` in a 10-wide row: `XXX_X_XX__` (one valid arrangement).

### Cell States

```
CellState:
  empty    — default, white/light background
  filled   — player filled (dark/theme color)
  marked   — player marked X (excluded)
  revealed — hint-revealed cell (sparkle indicator, permanently shown)
  error    — filled but wrong (flash red, then revert — if error checking on)
```

### Input Modes

- **Fill mode** (default): tap to fill, tap again to unfill.
- **Mark mode**: tap to place X, tap again to remove.
- Mode toggle: button in HUD, or hold two fingers briefly to switch.
- **Drag fill**: drag across multiple cells in a row/column to fill/mark in bulk.
- **Cell hint** (1 token): player taps the hint button, the grid enters "hint mode" (dimmed overlay), player taps any single cell to reveal whether it is filled or empty. The cell is permanently revealed with a sparkle indicator and transitions to `CellState.revealed`.
- **Row hint** (rewarded ad OR 3 tokens): reveals the complete solution for one full row. The grid enters "row hint mode" (row headers highlighted), player taps which row to reveal.
These are two distinct hint types with different costs and UI flows.

### Validation & Error Checking

- After each cell tap, compare current filled pattern against solution.
- If error checking on: wrong cell flashes red and reverts; costs 1 life.
- If error checking off (Pro/purist mode): no immediate feedback; player must logic their way through.
- 3 lives per puzzle. Lives persist across puzzles and regenerate over time (see Zero Lives Flow).

### Clue Auto-Satisfaction

- When a row or column is fully and correctly solved, clue numbers turn GREEN (#00E676) and the row/column gets a subtle overlay.
- Gold/yellow (#FFD700 range) is reserved exclusively for CTAs (buttons, star icons). It must not be used for clue satisfaction.
- This gives players clear, unambiguous progress feedback on complex puzzles.

### Star Rating Thresholds

| Stars | Condition |
|-------|-----------|
| 3 stars | Zero errors AND completion time under par time |
| 2 stars | Zero errors OR completion time under 2x par time |
| 1 star  | Puzzle completed (any condition) |

### Zero Lives Flow

- When the 3rd life is lost: the puzzle pauses immediately and a modal appears.
- Modal options:
  - **(a) Watch rewarded ad** — restores all 3 lives, puzzle resumes.
  - **(b) Wait** — 1 life regenerates after 30 minutes; player can close the app and return.
  - **(c) Quit puzzle** — progress is saved (see Mid-Puzzle Save/Resume); player returns to home screen.
- Lives regenerate at 1 life per 30 minutes, capped at a maximum of 3.
- Lives are a global player resource; they persist across puzzles and app sessions.

### Mid-Puzzle Save/Resume

- Auto-save occurs on every cell action and whenever the app enters the background.
- On resume, the puzzle is restored to its exact saved state: all cell values, timer paused, lives remaining.
- Saved state fields: `puzzleId`, `cells` (full grid), `livesRemaining`, `hintsUsed`, `elapsedSeconds`, `savedAt` timestamp.
- A puzzle in progress always shows a "Resume" indicator in the pack select screen.

### Scoring

```
Base score      = grid_size * 100    (5x5=500, 10x10=1000)
Error deduct    = -50 per mistake (if error checking on)
Time bonus      = max(0, (par_time - elapsed) * 5)
No-error bonus  = 200 if zero mistakes
Daily bonus     = score * 2
```

---

## 4. Progression System

### Picture Packs (MVP)

| Pack    | Unlock Condition | Puzzle Count | Grid Sizes |
|---------|-----------------|--------------|------------|
| Animals | Default (free)  | 15           | 5x5, 10x10 |
| Space   | Complete 10 Animal puzzles | 15 | 5x5, 10x10 |

Additional packs (Food, Holidays, Fantasy, Architecture) are planned for post-launch.

### Player Level

- XP per puzzle: 5x5=10xp, 10x10=30xp.
- No-error bonus: +50% XP.
- Level = floor(totalXP / 200), displayed on profile avatar.

### Difficulty Curve Within Each Pack

- Puzzles 1–5: unique solutions achievable by simple line logic (no trial-and-error needed).
- Puzzles 6–10: require cross-referencing multiple rows and columns.
- Puzzles 11–15: require advanced techniques (contradiction, forcing chains).

### Daily Puzzle

- Fixed 10x10 puzzle, same for all players, resets at midnight.
- Puzzle is selected deterministically from a dedicated daily puzzle pool of 60 puzzles (separate from packs) using a date-based seed (hash of the calendar date).
- One attempt per day. If the player runs out of lives (0 lives), the puzzle cannot be retried until tomorrow.
- In MVP, the completion time is displayed as the player's personal best. Online leaderboard submission launches in v1.1.
- Rewards on completion: +3 lives (capped at max 3), +100 XP, +1 hint token.

---

## 5. Monetization

### Ads (free players)

| Ad Type      | Trigger                                  | Frequency Cap    |
|--------------|------------------------------------------|------------------|
| Banner       | Visible on home + pack select screens    | Continuous       |
| Interstitial | Every 4th puzzle completion              | 1 per 5 min      |
| Rewarded     | "Restore 3 lives" (after all lives lost) | On demand        |
| Rewarded     | "Reveal one row solution" (row hint)     | Once per puzzle  |

### Hint System

- **Cell hint** (1 token): reveals whether a specific cell is filled or empty.
- **Row hint** (rewarded ad OR 3 tokens): reveals the complete solution for one row.
- Earn tokens: 1 per daily puzzle completion, 2 per pack completion.
- Buy tokens via IAP.

### IAP Products

| Product ID                | Price        | Description                                                     |
|---------------------------|--------------|-----------------------------------------------------------------|
| nonogram_remove_ads       | $2.99        | Remove banner + interstitial ads forever (consumable)           |
| nonogram_hint_pack_10     | $1.99        | 10 hint tokens (consumable)                                     |
| nonogram_pro              | $4.99/month  | No ads + purist mode + all packs + 5 hints/week + cloud save   |

- **Pro free trial**: 3-day free trial on first subscription.
- Purist mode (error checking off) is a Pro-only feature — it is not available as a standalone purchase.
- All IAP entitlements are verified server-side via RevenueCat (not raw StoreKit/Play Billing).

### Revenue Strategy

- Primary: `nonogram_pro` — high-value players who want the full experience.
- Secondary: hint token packs — mid-funnel players stuck on hard puzzles.
- Remove Ads targets players who are ad-averse but not ready for full Pro.

---

## 5.5. App Launch Sequence & Consent

### First Launch

1. **ATT prompt** (iOS only) — request App Tracking Transparency permission before any SDK initializes.
2. **GDPR/UMP consent form** (EEA and UK users only) — Google User Messaging Platform consent form; no ads load until consent is resolved.
3. **Age confirmation** — single tap to confirm the user is not a child (app is not directed to children).
4. **AdMob initialize** — initialize only after ATT and consent are resolved.
5. **Tutorial** — interactive guided first 5x5 puzzle (see Section 10).
6. **Home screen** — normal app entry point.

### Subsequent Launches

1. Check existing ATT status and UMP consent status.
2. AdMob initialize (immediately if consent not required, after UMP resolution if required).
3. Home screen.

### Privacy & COPPA

- Privacy policy URL displayed in the Settings screen and in the App Store/Play Store listing.
- COPPA: this app is NOT directed to children. App Store rating: 4+. Google Play rating: Everyone. AdMob is configured with standard (non-COPPA) treatment.
- Privacy policy states a minimum age of 13.
- **Data deletion**: a "Delete My Data" button in Settings removes all leaderboard entries and resets local progress (SharedPreferences wipe + Firestore deletion request).

### Leaderboard Security (v1.1, when online leaderboard launches)

- Backend: Firebase Firestore with Security Rules.
- Server-side time validation: submissions below a minimum plausible threshold for the grid size are rejected.
- Rate limiting: one submission per user per daily puzzle per 24-hour window.
- Display name: max 20 characters, alphanumeric and spaces only, server-side profanity blocklist.
- Firebase App Check for client attestation on all Firestore writes.

---

## 6. Code Reuse from Cube Blast

| Cube Blast File/System                       | Reuse in Nonogram                                                     |
|----------------------------------------------|-----------------------------------------------------------------------|
| `lib/utils/app_colors.dart`                  | Full reuse — add pack-specific palette entries                        |
| `lib/utils/storage.dart`                     | Full reuse — save level, XP, lives, hint tokens, progress             |
| `lib/utils/purchase_manager.dart`            | Full reuse — swap product IDs; MUST use RevenueCat for server-side receipt validation (not raw StoreKit/Billing) |
| `lib/utils/ad_manager.dart`                  | Full reuse — same AdMob integration                                   |
| `lib/utils/audio_manager.dart`               | Full reuse — add: cell_fill.mp3, row_complete.mp3, puzzle_reveal.mp3  |
| `lib/utils/leaderboard_service.dart`         | Full reuse — daily puzzle times (personal best in MVP, online in v1.1)|
| `lib/utils/analytics.dart`                   | Full reuse — add: cell_filled, row_complete, puzzle_complete events   |
| `lib/screens/settings_screen.dart`           | Full reuse — add Privacy Policy link and Delete My Data button        |
| `lib/screens/achievements_screen.dart`       | Full reuse — add nonogram achievements                                |
| `lib/screens/paywall_screen.dart`            | Full reuse — swap product IDs and copy; add 3-day trial messaging     |
| `lib/models/achievements.dart`               | Reuse structure, add new achievement definitions                      |
| `lib/models/game_themes.dart`                | Reuse theme model                                                     |
| `lib/widgets/achievement_popup.dart`         | Full reuse                                                            |
| `lib/widgets/score_particles.dart`           | Reuse for puzzle-complete burst                                       |

Note: `online_leaderboard_screen.dart` is deferred to v1.1 (post-launch).

---

## 7. New Code Required

### Core Puzzle Engine

- `lib/models/nonogram_puzzle.dart` — Puzzle definition: grid, clues, solution, metadata, color palette.
- `lib/models/nonogram_state.dart` — Live solve state: cell states, lives, hints used, timer, score.
- `lib/models/daily_puzzle.dart` — `DailyPuzzleRecord`: date, puzzleId, completionTime, submitted, rewardsClaimed.
- `lib/models/player_resources.dart` — `PlayerResources`: lives, hintTokens, lastLifeLostAt, totalXP, level (derived), displayName.
- `lib/models/puzzle_save_state.dart` — `PuzzleSaveState`: puzzleId, cells, livesRemaining, hintsUsed, elapsedSeconds, savedAt.
- `lib/utils/nonogram_generator.dart` — Algorithmic clue derivation from pixel grid; solvability checker.
- `lib/utils/nonogram_solver.dart` — Line-logic solver running in a background Isolate via `compute()`. **The solver must never run on the UI thread.**
- `lib/utils/pixel_art_data.dart` — Hard-coded pixel art grids for each pack puzzle.

### Architecture Notes

- **Solver isolation**: the nonogram solver MUST run in a background Isolate via `compute()`. Never run the solver on the UI thread.
- **Controller responsibilities**: `game_controller.dart` handles cell state coordination, validation dispatch, and hint consumption. The timer is a SEPARATE provider (`timer_controller.dart`). Score calculation is a pure function in the model layer — not inside the controller.

### Screens

- `lib/screens/home_screen.dart` — Pack grid, daily puzzle card, lives display, player level.
- `lib/screens/pack_select_screen.dart` — Pack browser with blurred preview thumbnails.
- `lib/screens/game_screen.dart` — Core puzzle: grid + clue headers + HUD.
- `lib/screens/puzzle_complete_screen.dart` — Pixel art reveal, stars, score, next CTA.
- `lib/screens/tutorial_screen.dart` — Guided interactive first 5x5 puzzle (MVP).

### Widgets

- `lib/widgets/nonogram_grid_widget.dart` — CustomPainter for the puzzle grid with tap/drag handling.
- `lib/widgets/clue_header_row.dart` — Column clue display (vertical number stacks, green on satisfaction).
- `lib/widgets/clue_header_col.dart` — Row clue display (horizontal number lists, green on satisfaction).
- `lib/widgets/lives_indicator.dart` — Heart icons showing remaining lives.
- `lib/widgets/mode_toggle.dart` — Fill/Mark mode switch button.
- `lib/widgets/pixel_art_reveal.dart` — Animated reveal of the completed picture.
- `lib/widgets/pack_thumbnail.dart` — Blurred puzzle preview card.

### Controllers

- `lib/controllers/game_controller.dart` — Riverpod AsyncNotifier: cell state coordination, validation dispatch, hint consumption.
- `lib/controllers/timer_controller.dart` — Isolated timer provider (StreamProvider, 1-second tick). Separate from game_controller.
- `lib/controllers/progress_controller.dart` — Pack/puzzle unlock, XP, level, hint tokens.
- `lib/controllers/daily_puzzle_controller.dart` — Date-based puzzle selection, one-per-day gating, personal best tracking, leaderboard submit (v1.1).

### Assets

- `assets/puzzles/*.json` — Pixel grid data for all puzzles.
- `assets/audio/cell_fill.mp3/.ogg`, `row_complete.mp3/.ogg`, `puzzle_reveal.mp3/.ogg`, `error.mp3/.ogg`

---

## 8. File Structure

```
lib/
  models/
    nonogram_puzzle.dart
    nonogram_state.dart
    daily_puzzle.dart         # DailyPuzzleRecord
    player_resources.dart     # PlayerResources (lives, tokens, XP)
    puzzle_save_state.dart    # Mid-puzzle save/resume
    achievements.dart         # Reused + new
    game_themes.dart          # Reused
  screens/
    home_screen.dart
    pack_select_screen.dart
    game_screen.dart
    puzzle_complete_screen.dart
    tutorial_screen.dart      # Guided first 5x5 (MVP)
    settings_screen.dart      # Reused + Privacy Policy + Delete My Data
    achievements_screen.dart  # Reused
    paywall_screen.dart       # Reused
  widgets/
    nonogram_grid_widget.dart
    clue_header_row.dart
    clue_header_col.dart
    lives_indicator.dart
    mode_toggle.dart
    pixel_art_reveal.dart
    pack_thumbnail.dart
    achievement_popup.dart    # Reused
    score_particles.dart      # Reused
  controllers/
    game_controller.dart
    timer_controller.dart     # Isolated StreamProvider (1-second tick)
    progress_controller.dart
    daily_puzzle_controller.dart
  utils/
    nonogram_generator.dart
    nonogram_solver.dart      # Runs in background Isolate via compute()
    pixel_art_data.dart
    app_colors.dart           # Reused
    storage.dart              # Reused
    audio_manager.dart        # Reused
    purchase_manager.dart     # Reused (RevenueCat server-side validation)
    ad_manager.dart           # Reused
    leaderboard_service.dart  # Reused
    analytics.dart            # Reused

assets/
  puzzles/
    animals.json              # Pixel grids for Animals pack
    space.json
    daily_pool.json           # 60 daily puzzles (separate pool)
  audio/
    cell_fill.mp3 / .ogg
    row_complete.mp3 / .ogg
    puzzle_reveal.mp3 / .ogg
    error.mp3 / .ogg
    bgm.mp3 / .ogg
```

### Security Considerations (Android)

- `android:allowBackup="false"` in `AndroidManifest.xml` to prevent local backup of game state.
- ProGuard/R8 obfuscation enabled for release builds.
- No debug logging (`print`, `debugPrint`) in release builds — enforced via `kReleaseMode` guards and lint.
- IAP entitlements verified via RevenueCat server-side receipt validation. Local entitlement cache is never the sole authority.
- Puzzle solutions must never appear in logs, analytics events, or crash reports.

---

## 9. Data Models

```dart
// lib/models/nonogram_puzzle.dart

// 0 = empty, 1+ = color palette index
// For gameplay, any non-zero cell is "filled" (color is irrelevant during solving).
// Color is used only for the reveal animation and gallery thumbnails.
typedef PixelGrid = List<List<int>>;

class NonogramClue {
  final List<int> runs;   // e.g., [3, 1, 2]

  const NonogramClue(this.runs);

  int get minLength => runs.isEmpty ? 0 : runs.reduce((a, b) => a + b) + runs.length - 1;

  bool get isEmpty => runs.isEmpty;
}

class NonogramPuzzle {
  final String id;
  final String title;
  final String packId;
  final int gridSize;                   // 5 or 10 (MVP); 15, 20 post-launch
  final PixelGrid solution;            // The correct answer (int grid)
  final List<NonogramClue> rowClues;   // One per row
  final List<NonogramClue> colClues;   // One per column
  final int parTimeSeconds;
  final int difficulty;                 // 1=easy, 2=medium, 3=hard, 4=expert
  final int orderIndex;                 // Display order within the pack
  final List<Color> colorPalette;      // e.g., [Colors.blue, Colors.yellow]
                                        // Index 0 = empty, index 1+ = fill colors

  const NonogramPuzzle({
    required this.id,
    required this.title,
    required this.packId,
    required this.gridSize,
    required this.solution,
    required this.rowClues,
    required this.colClues,
    required this.parTimeSeconds,
    required this.difficulty,
    required this.orderIndex,
    this.colorPalette = const [Colors.blue],
  });

  /// Derive clues from a pixel grid (for puzzle generation).
  /// Any non-zero value counts as "filled" for clue calculation.
  static NonogramPuzzle fromPixelGrid({
    required String id,
    required String title,
    required String packId,
    required PixelGrid grid,
    required int parTimeSeconds,
    required int difficulty,
    required int orderIndex,
    List<Color> colorPalette = const [Colors.blue],
  }) {
    final size = grid.length;
    final rowClues = grid.map((row) => NonogramClue(_runsFor(row))).toList();
    final colClues = List.generate(size, (col) {
      final colCells = List.generate(size, (row) => grid[row][col]);
      return NonogramClue(_runsFor(colCells));
    });
    return NonogramPuzzle(
      id: id,
      title: title,
      packId: packId,
      gridSize: size,
      solution: grid,
      rowClues: rowClues,
      colClues: colClues,
      parTimeSeconds: parTimeSeconds,
      difficulty: difficulty,
      orderIndex: orderIndex,
      colorPalette: colorPalette,
    );
  }

  static List<int> _runsFor(List<int> cells) {
    final runs = <int>[];
    int current = 0;
    for (final cell in cells) {
      if (cell != 0) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    return runs;
  }
}

// lib/models/nonogram_state.dart

enum CellState { empty, filled, marked, revealed }

class NonogramState {
  final NonogramPuzzle puzzle;
  final List<List<CellState>> cells;
  final int livesRemaining;
  final int hintsUsed;
  final int elapsedSeconds;
  final bool isComplete;
  final bool puristMode;           // No error checking (Pro only)
  final int score;

  const NonogramState({
    required this.puzzle,
    required this.cells,
    this.livesRemaining = 3,
    this.hintsUsed = 0,
    this.elapsedSeconds = 0,
    this.isComplete = false,
    this.puristMode = false,
    this.score = 0,
  });

  factory NonogramState.initial(NonogramPuzzle puzzle, {bool puristMode = false}) {
    final cells = List.generate(
      puzzle.gridSize,
      (_) => List.filled(puzzle.gridSize, CellState.empty),
    );
    return NonogramState(puzzle: puzzle, cells: cells, puristMode: puristMode);
  }

  bool isRowSatisfied(int row) {
    final filledCells = cells[row].map((c) => c == CellState.filled || c == CellState.revealed).toList();
    return _runsMatch(filledCells, puzzle.rowClues[row].runs);
  }

  bool isColSatisfied(int col) {
    final filledCells = List.generate(
      puzzle.gridSize,
      (row) => cells[row][col] == CellState.filled || cells[row][col] == CellState.revealed,
    );
    return _runsMatch(filledCells, puzzle.colClues[col].runs);
  }

  bool _runsMatch(List<bool> cells, List<int> expectedRuns) {
    final actualRuns = <int>[];
    int current = 0;
    for (final c in cells) {
      if (c) current++;
      else if (current > 0) { actualRuns.add(current); current = 0; }
    }
    if (current > 0) actualRuns.add(current);
    if (actualRuns.length != expectedRuns.length) return false;
    for (int i = 0; i < actualRuns.length; i++) {
      if (actualRuns[i] != expectedRuns[i]) return false;
    }
    return true;
  }

  bool get checkComplete {
    for (int r = 0; r < puzzle.gridSize; r++) {
      if (!isRowSatisfied(r)) return false;
    }
    for (int c = 0; c < puzzle.gridSize; c++) {
      if (!isColSatisfied(c)) return false;
    }
    return true;
  }

  NonogramState copyWith({
    List<List<CellState>>? cells,
    int? livesRemaining,
    int? hintsUsed,
    int? elapsedSeconds,
    bool? isComplete,
    int? score,
  }) => NonogramState(
    puzzle: puzzle,
    cells: cells ?? this.cells,
    livesRemaining: livesRemaining ?? this.livesRemaining,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    isComplete: isComplete ?? this.isComplete,
    puristMode: puristMode,
    score: score ?? this.score,
  );
}

// lib/models/puzzle_pack.dart

class PuzzlePack {
  final String id;
  final String name;
  final String emoji;
  final List<NonogramPuzzle> puzzles;
  final int unlockLevel;
  final bool requiresPro;
  final bool isDefault;

  const PuzzlePack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.puzzles,
    this.unlockLevel = 0,
    this.requiresPro = false,
    this.isDefault = false,
  });

  int starsFor(Map<String, PuzzleResult> results) =>
    puzzles.fold(0, (sum, p) => sum + (results[p.id]?.starsEarned ?? 0));

  double progressFor(Map<String, PuzzleResult> results) {
    if (puzzles.isEmpty) return 0;
    return puzzles.where((p) => results.containsKey(p.id)).length / puzzles.length;
  }
}

class PuzzleResult {
  final String puzzleId;
  final int starsEarned;
  final int timeSeconds;
  final int score;
  final int mistakeCount;
  final int hintsUsed;

  const PuzzleResult({
    required this.puzzleId,
    required this.starsEarned,
    required this.timeSeconds,
    required this.score,
    required this.mistakeCount,
    required this.hintsUsed,
  });

  Map<String, dynamic> toJson() => {
    'puzzleId': puzzleId,
    'starsEarned': starsEarned,
    'timeSeconds': timeSeconds,
    'score': score,
    'mistakeCount': mistakeCount,
    'hintsUsed': hintsUsed,
  };

  factory PuzzleResult.fromJson(Map<String, dynamic> json) => PuzzleResult(
    puzzleId: json['puzzleId'] as String,
    starsEarned: json['starsEarned'] as int,
    timeSeconds: json['timeSeconds'] as int,
    score: json['score'] as int,
    mistakeCount: json['mistakeCount'] as int,
    hintsUsed: json['hintsUsed'] as int,
  );
}

// lib/models/daily_puzzle.dart

class DailyPuzzleRecord {
  final String date;              // ISO 8601 date string, e.g. "2026-06-01"
  final String puzzleId;
  final int? completionTime;      // null if not yet completed
  final bool submitted;           // true once sent to leaderboard (v1.1)
  final bool rewardsClaimed;      // true once +3 lives / +100 XP / +1 token granted

  const DailyPuzzleRecord({
    required this.date,
    required this.puzzleId,
    this.completionTime,
    this.submitted = false,
    this.rewardsClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'puzzleId': puzzleId,
    'completionTime': completionTime,
    'submitted': submitted,
    'rewardsClaimed': rewardsClaimed,
  };

  factory DailyPuzzleRecord.fromJson(Map<String, dynamic> json) => DailyPuzzleRecord(
    date: json['date'] as String,
    puzzleId: json['puzzleId'] as String,
    completionTime: json['completionTime'] as int?,
    submitted: json['submitted'] as bool? ?? false,
    rewardsClaimed: json['rewardsClaimed'] as bool? ?? false,
  );
}

// lib/models/player_resources.dart

class PlayerResources {
  final int lives;                    // 0–3
  final int hintTokens;
  final DateTime? lastLifeLostAt;     // Used to calculate regen timing
  final int totalXP;
  final String displayName;

  const PlayerResources({
    this.lives = 3,
    this.hintTokens = 0,
    this.lastLifeLostAt,
    this.totalXP = 0,
    this.displayName = 'Player',
  });

  /// Level is derived from totalXP, not stored separately.
  int get level => totalXP ~/ 200;

  PlayerResources copyWith({
    int? lives,
    int? hintTokens,
    DateTime? lastLifeLostAt,
    int? totalXP,
    String? displayName,
  }) => PlayerResources(
    lives: lives ?? this.lives,
    hintTokens: hintTokens ?? this.hintTokens,
    lastLifeLostAt: lastLifeLostAt ?? this.lastLifeLostAt,
    totalXP: totalXP ?? this.totalXP,
    displayName: displayName ?? this.displayName,
  );
}

// lib/models/puzzle_save_state.dart

class PuzzleSaveState {
  final String puzzleId;
  final List<List<int>> cells;   // CellState index values (int for JSON serialization)
  final int livesRemaining;
  final int hintsUsed;
  final int elapsedSeconds;
  final DateTime savedAt;

  const PuzzleSaveState({
    required this.puzzleId,
    required this.cells,
    required this.livesRemaining,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'puzzleId': puzzleId,
    'cells': cells,
    'livesRemaining': livesRemaining,
    'hintsUsed': hintsUsed,
    'elapsedSeconds': elapsedSeconds,
    'savedAt': savedAt.toIso8601String(),
  };

  factory PuzzleSaveState.fromJson(Map<String, dynamic> json) => PuzzleSaveState(
    puzzleId: json['puzzleId'] as String,
    cells: (json['cells'] as List)
        .map((row) => (row as List).map((v) => v as int).toList())
        .toList(),
    livesRemaining: json['livesRemaining'] as int,
    hintsUsed: json['hintsUsed'] as int,
    elapsedSeconds: json['elapsedSeconds'] as int,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}
```

---

## 10. MVP Feature List

- [ ] ATT + GDPR/UMP consent flow (first launch)
- [ ] Privacy policy link in Settings
- [ ] "Delete My Data" button in Settings
- [ ] Interactive tutorial (guided first 5x5 puzzle)
- [ ] Nonogram grid renderer (CustomPainter, tap + drag input)
- [ ] Row/column clue display and satisfaction highlighting (green #00E676)
- [ ] Cell state cycling (empty → filled → marked → empty)
- [ ] Hint-revealed cell state (sparkle indicator, permanent)
- [ ] Cell hint flow (hint mode overlay, single-cell reveal, 1 token)
- [ ] Row hint flow (row selection overlay, full row reveal, rewarded ad or 3 tokens)
- [ ] Error checking with life system (3 lives)
- [ ] Zero lives modal (watch ad / wait / quit with save)
- [ ] Mid-puzzle auto-save and resume
- [ ] Pixel art reveal animation on completion
- [ ] 2 puzzle packs (Animals 15 puzzles, Space 15 puzzles — 5x5 and 10x10 only)
- [ ] Daily puzzle (date-seeded, one attempt per day, personal best display)
- [ ] Clue derivation utility (fromPixelGrid)
- [ ] Score system (base + time bonus + no-error bonus)
- [ ] Star rating per puzzle (1–3 stars with defined thresholds)
- [ ] Lives system: global resource, 30-min regen, cap 3
- [ ] Hint token system (earn + buy + cell hint + row hint)
- [ ] Timer display (isolated StreamProvider)
- [ ] 2 visual themes (reused from Cube Blast)
- [ ] Banner ads
- [ ] Interstitial ads (every 4th puzzle)
- [ ] Remove Ads IAP ($2.99)
- [ ] Hint Pack IAP ($1.99, 10 tokens)
- [ ] Pro subscription IAP ($4.99/month, 3-day free trial)
- [ ] Purist mode (Pro only)
- [ ] Progress persistence per puzzle
- [ ] Achievements: First Solve, 10 Puzzles Complete, 7-Day Daily Streak
- [ ] App icon + splash screen

**Deferred to Post-Launch / v1.1 (not in MVP):**
- 15x15 and 20x20 grid sizes
- Zoom and pan (InteractiveViewer)
- Online leaderboard (daily puzzle)
- Colored nonogram rendering
- Cloud save

---

## 11. Post-Launch Features

- **v1.1**: Online daily puzzle leaderboard (Firebase Firestore, App Check, server-side validation), cloud save sync
- **v1.2**: 15x15 and 20x20 grid sizes with pinch-to-zoom and pan (InteractiveViewer, sticky clue headers)
- **v1.3**: Colored nonograms (each clue group in a distinct color; cells must match the correct color)
- Additional packs: Food, Holidays, Fantasy, Architecture
- User-submitted pixel art puzzles (community packs)
- Puzzle creator tool (draw pixel art in-app, auto-generate nonogram)
- Cross-stitch / embroidery export (convert completed pixel art to pattern PDF)
- Speed run mode (no error checking, fastest-solve leaderboard)
- Seasonal packs (Christmas, Easter, etc.)
- Accessibility mode (larger cells, high contrast, cell count display)
- Achievements gallery (pixel art trophies for completed puzzles)

---

## 12. ASO Keywords

1. nonogram puzzle
2. picross puzzle
3. pixel art puzzle
4. logic puzzle game
5. number puzzle game
6. griddler puzzle
7. fill grid puzzle
8. brain puzzle offline
9. nonogram daily puzzle
10. picross offline

---

## 13. Estimated Build Time

| Component                                      | Weeks |
|------------------------------------------------|-------|
| Data models + clue derivation + solver (Isolate) | 1.0 |
| Grid renderer + tap/drag input                 | 1.5   |
| Clue headers + satisfaction highlighting       | 0.5   |
| Error checking + lives system + zero lives modal | 0.5  |
| Mid-puzzle save/resume                         | 0.5   |
| Hint system (cell hint + row hint flows)       | 0.5   |
| Pixel art reveal animation                     | 0.5   |
| Daily puzzle (date seed + one-per-day gating)  | 0.5   |
| Puzzle data (30 puzzles, 2 packs, 2 sizes)     | 1.5   |
| Pack select + progress screens                 | 0.5   |
| Puzzle complete screen + stars                 | 0.5   |
| Tutorial (guided 5x5)                          | 0.5   |
| ATT + GDPR/UMP consent flow                    | 0.5   |
| Reuse: themes, audio, ads, IAP (RevenueCat)    | 0.5   |
| Reuse: achievements (3 MVP)                    | 0.5   |
| Polish: animations, SFX                        | 1.0   |
| QA + device testing                            | 1.0   |
| **Total**                                      | **12 weeks** |
