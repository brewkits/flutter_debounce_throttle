# Contributing to flutter_debounce_throttle

Thank you for your interest in contributing! This document covers how to contribute and the release process.

---

## Getting Started

### Prerequisites

- Dart SDK `^3.0.0`
- Flutter SDK `>=3.0.0`
- Melos: `dart pub global activate melos`

### Setup

```bash
git clone https://github.com/brewkits/flutter_debounce_throttle
cd flutter_debounce_throttle
melos bootstrap
```

### Running Tests

```bash
# All packages
melos run test

# Core Dart package only
cd packages/dart_debounce_throttle && dart test

# Flutter package only
flutter test test/
```

### Code Style

```bash
melos run format   # auto-format
melos run analyze  # static analysis
```

---

## Release Policy

This project follows a **quality-first release cadence** to maintain user trust and prevent pub.dev score volatility.

### Release Rules

| Rule | Detail |
|------|--------|
| **Minimum gap** | At least **2 weeks** between releases |
| **Batch small fixes** | Metadata fixes, dart fix, dependency bumps → accumulate, don't release individually |
| **Feature threshold** | A release should contain ≥1 meaningful feature OR ≥3 bug fixes |
| **No solo metadata releases** | Description/pubspec-only changes are not worth a version bump |
| **No solo dependency bumps** | Bumping transitive deps alone → wait for next feature release |

### Version Semantics

```
MAJOR.MINOR.PATCH

PATCH (x.x.1): Bug fixes, dart fix, metadata, dep bumps (batch together)
MINOR (x.1.x): New features, new classes, new widgets (backward compatible)
MAJOR (1.x.x): Breaking API changes (minimize, communicate well in advance)
```

### What Counts as "Breaking Change"?

In this library, **behavior changes to defaults** are also treated as breaking:

- Changing default parameter values → document prominently in CHANGELOG
- Enabling/disabling auto-cleanup by default → mention migration path
- Renaming public classes → provide deprecated aliases for 1 major version

### Release Checklist

Before publishing:

- [ ] All tests pass (`melos run test`)
- [ ] Static analysis clean (`melos run analyze`)
- [ ] CHANGELOG updated for all packages
- [ ] Version bumped in all relevant `pubspec.yaml` files
- [ ] README Installation section shows latest version
- [ ] Test count badges are up to date
- [ ] At least 2 weeks since last release
- [ ] Dry-run publish succeeds (`melos run publish --dry-run`)

---

## How to Contribute

### Bug Reports

Open an issue with:
1. Package name + version
2. Minimal reproduction code
3. Expected vs actual behavior
4. Flutter/Dart SDK version

### Feature Requests

Open an issue with:
1. Use case description (what problem are you solving?)
2. Proposed API (code example)
3. Which package it belongs to

### Pull Requests

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Write tests for your change
4. Ensure all tests pass
5. Update CHANGELOG (under `## Unreleased`)
6. Open a PR with clear description

### PR Requirements

- [ ] Tests added/updated
- [ ] All existing tests pass
- [ ] No new lint warnings
- [ ] CHANGELOG updated
- [ ] Minimal scope (one feature/fix per PR)

---

## Package Architecture

```
flutter_debounce_throttle/         ← Monorepo root
├── packages/
│   ├── dart_debounce_throttle/    ← Pure Dart core (no Flutter deps)
│   ├── flutter_debounce_throttle/ ← Flutter integration (widgets, mixin)
│   ├── flutter_debounce_throttle_hooks/  ← Optional flutter_hooks integration
│   └── flutter_debounce_throttle_core/  ← Deprecated (renamed to dart_*)
├── test/                          ← Integration test suite
├── example/                       ← Flutter demo app
├── docs/                          ← API reference, best practices
├── melos.yaml                     ← Monorepo config
└── CONTRIBUTING.md                ← This file
```

**Dependency rule:** `dart_debounce_throttle` has zero Flutter dependencies. Never add Flutter imports there. `flutter_debounce_throttle` depends on `dart_debounce_throttle`. `hooks` depends on `flutter_debounce_throttle`.

---

## Questions?

Open an issue on [GitHub](https://github.com/brewkits/flutter_debounce_throttle/issues).
