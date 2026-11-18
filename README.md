# Chipmunk iOS prototype

Chipmunk is a women-centered, science-forward health learning app for ages 16+. This repository contains the first native SwiftUI MVP shell.

## Included

- Choose a women’s health or mental health track; beginner start is the default.
- Optional two-question placement check. A perfect score opens the second foundation lesson while keeping lesson one available for review.
- Sequential learning paths with ten foundation lessons in each track, progressing from core concepts to more specific physiology and mental-health science.
- Color-coded, underlined keywords, flip-style vocabulary flashcards, and shared care rewards in both tracks.
- A cumulative ten-question review quiz after lesson ten in each track.
- A Collection screen with shared care-streak badges and a named chipmunk companion.
- A daily-care meter that starts at 0 and measures the share of all five needs refilled today. It reaches 100 only when all five are full. Lessons add 10 to the lowest need, activities add 5, and the unit quiz adds 10; each need halves at the next local day.
- Chip starts at age 16 and gains one year per 10 unique lessons completed across both tracks, up to age 100.
- A day streak based on completing at least one lesson or interactive activity on consecutive local calendar days.
- Companion accent colors unlocked by earning care-streak badges; lifetime XP and lesson-specific badges are not used.
- The chipmunk emoji is used as the iOS app icon and Collection companion.
- A short next-lesson teaser after a completed lesson.
- Distinct media in the first ten mental-health lessons: breathing rhythm, tap-to-build context map, stress-response pathway, sleep timeline, anxiety continuum model, evidence-lens cards, focus-switch mini-game, supportive-response scenario, life-stage timeline, and evidence-literacy choice. The women’s-health course uses a topic-specific visual diagram in each lesson.
- Multiple-choice checks, immediate feedback, locally saved daily care, completed lessons, and a local-calendar day streak.
- Reference library entries for completed lessons.
- Reflection notes saved locally on the device.

## Open in Xcode

Open `ios/Chipmunk.xcodeproj`, select an iPhone simulator, and run the `Chipmunk` scheme with **Product → Run** (⌘R). The app targets iOS 17 and uses the bundle identifier `com.chipmunk.learn`.

To run on a physical iPhone, connect it to the Mac with a data-capable cable, unlock it, and tap **Trust** if prompted. In Xcode, choose the iPhone as the run destination. If requested, enable **Settings → Privacy & Security → Developer Mode** on the phone and select your Apple Account under the app target’s **Signing & Capabilities** settings.

Xcode 27.2 is installed on the development Mac. Lessons include visual guides, highlighted key terms, and expandable concept maps in the reference library. Sources link to OpenStax, NIH/NIMH, and the U.S. Office on Women’s Health. Activities are educational prototypes and do not screen for or diagnose a condition; course content will need editorial and clinical review before release.

## Product direction

See [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) for the research-led curriculum, evidence standards, content scope, and visual direction. These two ten-lesson foundation paths are the first course unit, not the full course catalog.
