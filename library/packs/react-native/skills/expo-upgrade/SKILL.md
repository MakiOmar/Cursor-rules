---
name: expo-upgrade
description: Aligns an Expo app with its SDK's patch versions or upgrades it to a new Expo SDK / React Native major, with native rebuild and regression checks. Use when the user asks to update React, React Native, or Expo, fix expo-doctor or expo install --check warnings, or move to a new SDK.
---

# Expo upgrade

## Project values

| Value | Example |
|-------|---------|
| App folder | `{{mobile_dir}}` |
| Custom config plugins to re-verify | `{{plugins}}` |
| Smoke-test flows | `{{flows}}` (boot, gates, main CRUD, notifications, backup, RTL) |
| Release build command | `{{release_build}}` |

## 1. Assess (read-only)

1. `npx expo install --check`, `npx expo-doctor`, `npm outdated`, and the type check (`tsc --noEmit`).
2. Separate the result into: patch drift inside the current SDK, config-schema errors, and newer majors.
3. Report to the user before changing anything; a new SDK major needs explicit approval.

## 2. Patch alignment (same SDK)

1. Commit or stash unrelated work so the upgrade is its own commit.
2. `npx expo install --fix`, then fix any config-schema errors expo-doctor reported.
3. Type check, `npx expo prebuild --clean` (if native folders are generated), debug build on device or emulator, run the smoke-test flows.

## 3. SDK major upgrade

1. Read the SDK changelog and upgrade guide for every SDK between current and target, and the React Native release notes; list breaking changes that touch this app.
2. Use a branch. `npx expo install expo@^<target>` then `npx expo install --fix`.
3. Re-verify each custom config plugin against the new templates (anchors, file names, Gradle/AGP versions); plugins must throw on a missing anchor.
4. Check RTL bootstrap, splash, edge-to-edge and keyboard behavior, notifications, and any legacy native modules under the new architecture.
5. `npx expo prebuild --clean`, release build with `{{release_build}}`, then run the smoke-test flows on a real device.
6. Bump the app version and build number; note store-facing changes (target SDK, new permissions).

## Never

- Bump `react`, `react-native`, or SDK-pinned packages individually to "latest".
- Mix the upgrade with feature work or the Meta / analytics / billing changes in one commit.
