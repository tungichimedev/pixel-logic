# Workflow State — Pixel Logic (Nonogram)

## Current Phase: 3 — Prototype (WELL INTO PRODUCTION)
## Status: In Progress — Core app playable

## Phase History

### Phase 1: Concept — COMPLETE (pre-existing)
- CONCEPT.md: full game concept with mechanics, monetization, data models

### Phase 2: Design — COMPLETE (2026-06-01)
- design.html v4: 13 screens, premium art direction (Press Start 2P, glassmorphism, confetti)
- CONCEPT.md v2: all spec gaps fixed (star thresholds, zero lives, hints, consent)
- Full 5-agent review + art director review applied
- GitHub repo created with 50 issues, 3 milestones

### Phase 3: Prototype / Production — IN PROGRESS (2026-06-01)
- Flutter project scaffolded with Riverpod, GoRouter, SharedPreferences
- 8 screens fully functional
- 30 puzzles across 2 packs
- Core game loop complete and playable

## What's Built (2026-06-01)

### Screens (8/13 designed screens implemented)
| Screen | Issue | Status |
|--------|-------|--------|
| Tutorial | #26 | Done — 4-step interactive, first launch |
| Home | #16 | Done — daily banner, level/XP, packs |
| Pack Select | #19 | Done — puzzle grid, stars, locked states |
| Gameplay | #17 | Done — grid, drag, clues, timer, lives, toggle |
| Zero Lives | #22 | Done — restore/exit modal |
| Completion | #18 | Done — stars, score, stats, next |
| Gallery | #20 | Done — collection view, empty state |
| Settings | #21 | Done — toggles, stats, Pro banner, delete |

### Core Engine
| Component | Issue | Status |
|-----------|-------|--------|
| NonogramPuzzle model | #2 | Done |
| NonogramState model | #2 | Done |
| PuzzlePack model | #2 | Done |
| Clue derivation | #4 | Done |
| Game controller | #6 | Done |
| Progress controller | #8 | Done |
| Daily controller | #31 | Done |
| Achievements | #30 | Done — 3 achievements |
| GoRouter | #42 | Done |
| App theme | #43 | Done |

### Content
- Animals: 15 puzzles (8x5x5, 7x10x10) — COMPLETE
- Space: 15 puzzles (8x5x5, 7x10x10) — COMPLETE
- Total: 30 puzzles — MVP target reached

### GitHub Issues Completed: ~20 of 50

## What's Left for MVP

### High Priority
- [ ] Solver (#5) — puzzle uniqueness verification
- [ ] Puzzle asset loader (#44) — JSON pipeline (currently hardcoded)
- [ ] Storage layer (#47) — debounced writes, proper abstraction
- [ ] Lifecycle handler (#46) — background/foreground coordination
- [ ] ATT + GDPR consent (#37) — legal requirement
- [ ] AdMob ads (#38) — revenue
- [ ] RevenueCat IAP (#39) — subscriptions
- [ ] Paywall screen (#25)

### Medium Priority
- [ ] Audio SFX (#29)
- [ ] Mid-puzzle save/resume (#51)
- [ ] App icon + splash (#45)
- [ ] Build config (#52) — signing, dart-define
- [ ] ProGuard/R8 (#48)
- [ ] Daily puzzle pool (#41) — 60 additional puzzles
- [ ] Privacy policy (#33)
- [ ] Delete data e2e (#49)
- [ ] Analytics (#50)

## Key Decisions
1-12: See earlier decisions (unchanged)
13. 30 puzzles hardcoded in Dart for prototype speed; will move to JSON assets later
14. Achievements use SharedPreferences with popup SnackBar
15. Bottom nav with 3 tabs (Home, Gallery, Settings)
