# Design Match Spec — All 16 Screens to Match design.html v5

> Match every screen in the Flutter app to the HTML design mockup pixel-perfectly.
> Approach: Full UI, placeholder callbacks for SDK-dependent features.

## Source of Truth
- `design.html` v5 — 16 screens across 4 rows (Onboarding, Core Flow, Additional, States/Overlays)

## Phase A — Polish 8 Existing Screens

### A1. Tutorial Screen (`tutorial_screen.dart`)
Design reference: Screen 7 (Tutorial / How To Play)
- [x] Press Start 2P font on "HOW TO PLAY" title (DONE)
- [x] Gradient background (DONE)
- [x] Step-specific visual hint cards (DONE)
- [x] Skip button as TextButton (DONE)
- [ ] Match tooltip styling from design (glassmorphism tooltip with gold border)
- [ ] Pulsing gold border on target cell (step 1: row 3 cells)
- [ ] 4-step progress dots matching design (active = gold pill, inactive = grey dot)

### A2. Home Screen (`home_screen.dart`)
Design reference: Screen 1 (Home)
- [x] Pixel font on PIXEL LOGIC + NONOGRAM PUZZLES (DONE)
- [x] Gradient background (DONE)
- [x] Daily banner font size 11px (DONE)
- [x] Pulsing heart (DONE)
- [ ] Gradient line separator (replace any remaining diamond)
- [ ] Lock non-existent packs (Food/Holiday/Fantasy/Arch) — only Animals+Space unlockable
- [ ] Size selector chips (5x5 / 10x10) matching design
- [ ] Glassmorphism bottom nav with blur + gradient divider line

### A3. Game Screen (`game_screen.dart`)
Design reference: Screen 2 (Gameplay)
- [x] Gradient background (DONE)
- [x] Progress bar 6px (DONE)
- [x] HUD rows+cols count (DONE)
- [x] Mode toggle margin fixed (DONE)
- [x] Star animation on completion (DONE)
- [ ] Glassmorphism on Zero Lives overlay (backdrop blur + saturate)
- [ ] Glassmorphism on Completion overlay
- [ ] Top bar: gradient divider line instead of border
- [ ] Hint circle button matching design (round gold circle with ? icon)

### A4. Pack Select Screen (`pack_select_screen.dart`)
Design reference: Screen 5 (Pack Select)
- [x] Gradient background (DONE)
- [x] Font sizes 11px/10px (DONE)
- [x] Aspect ratio 0.75 (DONE)
- [ ] SVG pixel art thumbnails on completed puzzle tiles (like gallery)
- [ ] "MORE SOON" placeholder instead of locked packs tab bar
- [ ] Progress bar gradient (gold) matching design

### A5. Gallery Screen (`gallery_screen.dart`)
Design reference: Screen 6 (Gallery)
- [x] Gradient background (DONE)
- [x] Pixel font on GALLERY title (DONE)
- [x] Pixel art thumbnails (DONE)
- [x] Empty state CTA (DONE)
- [ ] Pack filter chips (ALL / Animals / Space)
- [ ] Progress card matching design (pack name, progress bar, stars count)
- [ ] Done thumbnails with green gradient bg + expand icon
- [ ] Locked thumbnails with lock icon

### A6. Settings Screen (`settings_screen.dart`)
Design reference: Screen 8 (Settings)
- [x] Gradient background (DONE)
- [x] Pixel font on SETTINGS title (DONE)
- [x] Switch height fixed (DONE)
- [x] Pro price placeholder (DONE)
- [ ] Error Checking row: incentive copy "Disable for the ultimate challenge"
- [ ] PRO banner matching design (gradient border, icon)
- [ ] Section dividers matching design (gradient lines)

### A7. Main Shell (`main_shell.dart`)
Design reference: Bottom nav across all screens
- [ ] 3-tab nav (Home / Gallery / Settings) — remove any 4th tab
- [ ] Glassmorphism: backdrop-filter blur(12px) + gradient bg
- [ ] Gradient divider line at top of nav
- [ ] Gold active dot below active tab label

### A8. Grid Widget (`nonogram_grid_widget.dart`)
- [x] Cell size clamp 32-52 (DONE)
- [ ] Satisfied row/col: green glow background on clue container (matching design)
- [ ] Filled cells: 4-directional inner shadows matching design

## Phase B — Build 3 Onboarding Screens (NEW)

### B1. Onboarding Screen (`onboarding_screen.dart` — NEW)
Design reference: Onboarding 1-3
- PageView with 3 pages, page indicator dots, Skip + Next/CTA buttons
- Page 1 (Welcome): Large pixel heart grid, PIXEL LOGIC title (gold gradient), tagline
- Page 2 (How It Works): 3 step cards (Read Clues, Fill Cells, Reveal), before/after demo
- Page 3 (Get Started): 5 feature value prop cards, "LET'S PLAY!" CTA
- On complete: mark onboarding as done in SharedPreferences, navigate to tutorial
- Replaces current tutorial as the first-launch entry point
- Flow: Onboarding -> Tutorial -> Home

### B2. Integration
- `main_shell.dart`: check `onboarding_complete` pref, show OnboardingScreen if false
- After onboarding completes, show TutorialScreen (existing)
- After tutorial completes, show Home (existing)

## Phase C — Build 3 New Screens (Placeholder Callbacks)

### C1. Paywall Screen (`paywall_screen.dart` — NEW)
Design reference: Screen 9 (Paywall)
- Accessible from Settings PRO banner tap + locked features
- Hero section: pixel art star icon, "PIXEL LOGIC PRO" title
- Feature list: No Ads, All Packs, Weekly Hints, Purist Mode (shield icon)
- Pricing: Monthly ($1.99/mo) + Annual ($9.99/yr) options
- "TRY FREE FOR 3 DAYS" gold CTA button
- "Restore Purchases" text link
- All purchase buttons: placeholder `onTap: () {}` with TODO comment
- Route: `/paywall` via GoRouter

### C2. Achievements Screen (`achievements_screen.dart` — NEW)
Design reference: Screen 10 (Achievements)
- Full-screen view (not just SnackBar popup)
- List of achievement cards: unlocked (gold gradient bg), in-progress (blue bar), locked (dim)
- Each card: icon, title, description, progress bar
- Uses existing `achievementsProvider` data
- Accessible from Settings or Home
- Route: GoRouter push from settings

### C3. Rewarded Ad Modal (`rewarded_ad_modal.dart` — NEW)
Design reference: Screen 13 (Rewarded Ad Prompt)
- Glassmorphism modal overlay (same as Zero Lives)
- Icon + "Watch a short video" title
- Value prop: "Get 3 extra lives to keep solving"
- Gold "Watch Ad" CTA button — placeholder just restores lives
- Ghost "No thanks" secondary button
- Shown from Zero Lives overlay "Watch Ad" button

## Architecture Notes
- All new screens use `GradientBackground` wrapper
- All titles use `AppFonts.pixel()` from `app_theme.dart`
- All overlays use glassmorphism (BackdropFilter + blur)
- No new packages needed (use existing google_fonts, riverpod, go_router)
- Colors from `AppColors`, gradients from `AppGradients`
