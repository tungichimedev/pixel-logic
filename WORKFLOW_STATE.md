# Workflow State — Pixel Logic (Nonogram)

## Current Phase: 2 — Design (COMPLETE, pending re-review)
## Status: Gate Review

## Phase History

### Phase 1: Concept — COMPLETE (pre-existing)
- CONCEPT.md created with full game design
- Date: pre-session

### Phase 2: Design — COMPLETE (2026-06-01)
- design.html v1 created (4 screens)
- Full 5-agent review conducted (Tier 3)
- Result: FAIL (17 Critical, 25 Major, 21 Minor)
- design.html v2 rewritten (8 screens, all issues addressed)
- CONCEPT.md rewritten with all spec gaps fixed
- Pending: re-review to confirm PASS

## Key Decisions Made (2026-06-01)
1. MVP scope: 5x5 and 10x10 only (15x15/20x20 deferred to v1.2)
2. Online leaderboard deferred to v1.1 (personal best in MVP)
3. Pixel art color format: int-based (0=empty, 1+=color palette index)
4. Daily puzzle: local date-based seed from 60-puzzle pool
5. IAP simplified to 3 products (remove ads, hint pack, Pro subscription)
6. Pro is now $4.99/month subscription with 3-day trial
7. Purist mode: Pro-only (no standalone IAP)
8. ATT + GDPR consent flow required before AdMob init
9. RevenueCat for server-side IAP validation
10. Solver runs in background Isolate (never UI thread)
11. Timer is a separate provider (not in game controller)
12. Tutorial (guided 5x5) added to MVP

## Next Steps
1. Re-review design (full 5-agent Tier 3) to confirm PASS
2. If PASS → Phase 3: Prototype (scaffold Flutter project)
3. Use /game-prototype to build playable grey-box prototype
