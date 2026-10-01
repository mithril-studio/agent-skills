---
name: ship-ios
description: Release an iOS or macOS app in two gated steps — build a downloadable test version from origin/test, hand it to the user to try, and only after they accept it open the PR from test to main that fires the production release pipeline. Use when the user says "ship iOS", "ship the app", "make a test build", "cut a test version", "TestFlight it", "build me something I can install", "release to production", "promote test to main", or asks whether a build is ready to go out. For repos with an Xcode project or workspace; the app itself is built by Xcode tooling or the repo's own pipeline, never hand-assembled.
---

# Ship iOS

These apps live on two branches. `test` is where all work lands; `main` is production and
only ever moves by a pull request from `test`. Shipping is two gates, and the user holds the
key to the second one:

1. **Test gate.** Turn `origin/test` into a build the user can install and try: a TestFlight
   build or an `.ipa` for iOS, a notarized `.dmg` or `.zip` for macOS.
2. **Release gate.** Once the user says the tested build is accepted, open the PR from `test`
   to `main`, merge it the way the repo's rules say, and confirm the production pipeline ran.

Never cross from gate 1 to gate 2 on your own. "Looks good" about the code is not acceptance;
acceptance is the user saying the *installed build* is the one to release.

## Before anything: does the repo already know how to release?

Look for a release pipeline before you build one by hand:

- `fastlane/Fastfile` lanes (`beta`, `release`, `testflight`), `.github/workflows/*.yml`
  that archive or upload, Xcode Cloud (`ci_scripts/`, workflows in App Store Connect),
  `scripts/release.sh`, a `release` target in a Makefile or justfile.
- A Release or Deployment section in `AGENTS.md`, `CLAUDE.md`, or the README.

- **A pipeline exists.** Trigger it, the way its docs say to (`gh workflow run`, `fastlane
  beta`, push a tag). The pipeline is the procedure for producing builds; this skill only
  supplies the gates around it.
- **Notes exist but no pipeline.** Take every value from them; the steps below apply.
- **Nothing exists.** Work it out in step 1, confirm with the user before signing or
  uploading anything, and write it down at the end.

## 1. Pin down the target

Find each in the repo first, ask second. Never guess a scheme, team, or bundle id.

| Fact | Where it lives |
|---|---|
| Project or workspace | `*.xcworkspace` beats `*.xcodeproj`; `Package.swift` apps build through their generated project |
| Scheme and configuration | `xcodebuild -list -json`; the shared scheme the pipeline uses, `Release` configuration |
| Platform | iOS, macOS, or both targets; decides the artifact and the distribution method |
| Bundle id and team | `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM` in the pbxproj or `*.xcconfig` |
| Version and build number | `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; or `Info.plist`; or the pipeline sets them |
| Signing for test builds | `ExportOptions.plist` method: `app-store-connect` (TestFlight), `ad-hoc` (iOS devices by UDID), `developer-id` (macOS outside the store) |
| Where the test build goes | TestFlight, a GitHub pre-release, an S3 bucket, a shared folder; the pipeline or notes say |
| Production pipeline | What runs on `main`: the workflow name, the Fastlane lane, the Xcode Cloud workflow, and what it does (upload to App Store Connect, submit for review, publish a GitHub release) |

## 2. Decide what ships: `origin/test` as it is

What gets built is `origin/test`, never a working tree.

```bash
git fetch origin test main
WANT=$(git rev-parse origin/test)
git log --oneline origin/main..origin/test     # what this release contains
```

- Unpushed local commits the user wants in: land them on `test` the way the repo's rules
  say, re-fetch, and recompute `WANT`. Say explicitly if you ship without them.
- `origin/main..origin/test` empty: there is nothing to release. Say so and stop.
- `origin/test..origin/main` not empty: `main` has commits `test` lacks (a hotfix). Stop and
  report; the user decides whether to merge `main` back into `test` first.

## 3. Preflight

Work from a clean checkout of `WANT`, not from a dirty tree:

```bash
git worktree add /tmp/ship-ios-${WANT:0:7} "$WANT"
```

In it, the same build and tests CI runs, with Release configuration. If the repo has no CI,
at minimum:

```bash
xcodebuild -workspace APP.xcworkspace -scheme SCHEME -configuration Release \
  -destination 'generic/platform=iOS' build 2>&1 | tee /tmp/ship-ios-build.log
xcodebuild ... test -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tee /tmp/ship-ios-test.log
```

Anything over ten seconds goes in a background command; poll its log, never `sleep`. Decide
a wait budget first and report if the build blows past it.

**Version and build number.** TestFlight and App Store Connect refuse a build number they
have already seen for that version. Find the last uploaded one (the pipeline's logs, `fastlane
latest_testflight_build_number`, or App Store Connect) and make sure the next is greater. If
the repo bumps numbers in a commit, that commit goes on `test` before you build, so `WANT`
moves; recompute it. If the pipeline derives the number from CI or the commit count, leave it
alone.

A failing build or test ends the attempt. Fix it on `test` and start again from step 2. Do
not edit signing settings, entitlements, or provisioning to get a green build.

## 4. Produce the test build

Prefer the repo's pipeline. By hand, the shape is archive then export:

```bash
xcodebuild -workspace APP.xcworkspace -scheme SCHEME -configuration Release \
  -destination 'generic/platform=iOS' -archivePath /tmp/ship-ios/APP.xcarchive \
  archive 2>&1 | tee /tmp/ship-ios-archive.log
xcodebuild -exportArchive -archivePath /tmp/ship-ios/APP.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath /tmp/ship-ios/export 2>&1 | tee /tmp/ship-ios-export.log
```

What comes out depends on platform and method:

| Platform | Method | Artifact | How the user installs it |
|---|---|---|---|
| iOS | `app-store-connect` | upload to TestFlight | TestFlight app, internal testers see it within minutes, no review |
| iOS | `ad-hoc` | `APP.ipa` | Device must be in the profile; install via Finder, Apple Configurator, or an OTA `manifest.plist` link |
| macOS | `developer-id` | `APP.app` in a `.dmg` or `.zip`, notarized | Download, open; Gatekeeper accepts it because it is stapled |
| macOS | `app-store-connect` | upload to TestFlight | TestFlight for Mac |

For macOS outside the store, notarize before calling it downloadable:

```bash
xcrun notarytool submit APP.zip --keychain-profile PROFILE --wait
xcrun stapler staple APP.app      # then re-zip or build the dmg from the stapled app
spctl -a -vv APP.app              # must say "accepted" and "Notarized Developer ID"
```

**Make it findable.** Put the artifact where the repo says test builds go. Lacking a rule,
attach it to a GitHub pre-release on a tag that names the candidate:

```bash
TAG="v${VERSION}-test.${BUILD}"
git tag -a "$TAG" "$WANT" -m "Test build $BUILD of $VERSION" && git push origin "$TAG"
gh release create "$TAG" /tmp/ship-ios/export/APP.ipa --prerelease --target "$WANT" \
  --title "$VERSION ($BUILD) test build" --notes-file /tmp/ship-ios-notes.md
```

The notes are the commit list from step 2 plus install instructions. A TestFlight build needs
no file; the tag still goes on `WANT`, so the accepted commit is named.

## 5. Hand it over, then stop

Report, in one block:

- Version and build number, platform, the tag, and `WANT` (short SHA).
- Where the build is and how to install it: the TestFlight link, the release URL, the file.
- What changed: the commit list from step 2, grouped if it is long.
- What you verified: build passed, tests passed, notarization accepted, upload processed.
- Anything the user should try first, from the commits.

Then wait. The user tests on a device. Three outcomes:

- **Accepted** ("accepted", "ship it", "release it", "go to production", or words to that
  effect about *this build*): continue to step 6 with this `WANT` and tag.
- **Changes wanted.** The fix lands on `test` like any other work. Go back to step 2; the
  next candidate gets the next build number and tag. Never patch the artifact.
- **Silence.** Nothing happens. Do not promote a build nobody accepted.

If `origin/test` has moved since the accepted build, say so before promoting: what the user
tested is `WANT`, and the PR would carry more than that. Either they accept the newer head
after a fresh build, or the PR is opened from the accepted tag.

## 6. Promote: pull request from `test` to `main`

```bash
gh pr create --base main --head test \
  --title "Release ${VERSION} (${BUILD})" --body-file /tmp/ship-ios-pr.md
```

The body says which build was tested and accepted (tag, SHA, link to the artifact), lists
the commits, and names the pipeline that will run on merge. Confirm the PR's head equals
`WANT`.

Merge the way the repo's rules say: a merge commit keeps `test` and `main` in step and is the
default when nothing says otherwise. Do not squash unless the repo does; a squashed `main`
diverges from `test` and the next release conflicts. If the repo requires human approval or
a green check, wait for it. Never push to `main` directly, and never force anything.

## 7. Watch the production pipeline

Merging is not releasing; the pipeline is. Find the run it triggered and watch it finish:

```bash
gh run list --branch main --limit 3
gh run watch RUN_ID --exit-status
```

For Xcode Cloud or Fastlane run from a laptop, the equivalent is the workflow's status page
or the lane's exit code. If the pipeline wants a tag on `main` (`v1.4.0`) rather than a merge,
tag the merge commit and push the tag; the version is the one from the accepted build.

Confirm what the pipeline promises: the build appears in App Store Connect with the expected
version and build number, the release is published, the submission is in review. If the
pipeline also submits for App Store review and the user did not ask for that, stop before
that step and ask.

A failed pipeline does not get retried blindly. Read the log, report it, and fix forward on
`test` if the fix is in code; `main` stays where it is.

## 8. Report

- Version, build, `WANT`, the test tag, the PR, the merge commit, the pipeline run and its
  result.
- What was confirmed in App Store Connect or on the release page.
- Anything left for the user: App Store review, phased release, release notes to edit.

## Leave the repo smarter than you found it

If you had to work out step 1, propose a Release section for `AGENTS.md`: the facts table,
the pipeline names, the bump policy, where test builds go. The next release should not
rediscover any of it.

## Hard rules

- `test` is the only branch that ships. `main` moves only by a PR from `test`.
- No release without an accepted test build, and the accepted build is the one that ships.
- Never print or commit signing certificates, provisioning profiles, App Store Connect API
  keys, or notarization credentials. They live in the keychain, CI secrets, or `.env`.
- Never change signing, entitlements, or bundle ids to make a build pass.
- Build numbers only go up. Never reuse one, never upload the same number twice.
- Tag the commit, never the working tree. Clean the worktree when done:
  `git worktree remove /tmp/ship-ios-<short>`.
