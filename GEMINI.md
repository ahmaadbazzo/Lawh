# GEMINI.md — Lawh (لَوح)

## Project context
- This is a Flutter application named Lawh (لَوح).
- The repository's default development branch is `main`.
- The app includes Quran reading and recitation/testing screens.
- The current CI workflow builds Android APK and AAB artifacts.

## Working rules
- Preserve Quran text, Uthmani script, verse numbering, page layout, and stop marks.
- Treat Quran rendering, fonts, page data, and recitation matching as correctness-critical.
- Do not replace Quran packages or change the Mushaf data format without explaining the trade-offs first.
- Prefer small, typed, testable changes over broad refactors.
- When diagnosing a bug, identify the exact source file, line, runtime type, and reproduction path.
- Add or update tests for fixes whenever practical.
- Run relevant Flutter checks (at minimum `flutter analyze` and applicable tests) when the environment permits; clearly report checks that could not be run.
- Never claim that a successful CI build proves the app works on a physical Android device.
- Do not commit, push, deploy, modify GitHub settings, or access secrets unless a human explicitly authorizes that action in the current task.
- Never print API keys, tokens, credentials, or private user data.
