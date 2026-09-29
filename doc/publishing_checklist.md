# Publishing checklist

Follow these steps once, in order, from the root of the package.

## 1. Create the GitHub repository

The pubspec points to `https://github.com/1shabbirhussain/image_color_backdrop`.
Create an empty public repository with that name (or edit `repository:` and
`issue_tracker:` in `pubspec.yaml` if you use another name), then push:

```sh
git init
git add .
git commit -m "Initial release"
git branch -M main
git remote add origin https://github.com/1shabbirhussain/image_color_backdrop.git
git push -u origin main
```

pub.dev checks that the repository URL is reachable, so push before
publishing.

## 2. Verify locally

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

All four must finish without changes or problems. `dart format .` rewrites
files if needed; commit the result.

Run the example once to see everything working:

```sh
cd example
flutter create .
flutter run
```

## 3. Screenshots

The `screenshots/` folder already contains images of the example app, and
`pubspec.yaml` lists them under `screenshots:`, so pub.dev shows them in the
package gallery. The README also embeds them through
`raw.githubusercontent.com` URLs, which work once the files are pushed to the
`main` branch. Each screenshot must be under 4 MB and its description under
160 characters. To replace one, keep the file name or update the `path:` entry.

## 4. Dry run

```sh
dart pub publish --dry-run
```

It must report `Package has 0 warnings.` Typical fixes: commit all files,
make sure `LICENSE`, `README.md` and `CHANGELOG.md` exist, and keep the
description between 60 and 180 characters.

## 5. Publish

```sh
dart pub publish
```

The first publish asks you to sign in with a Google account in the browser.
That account becomes the package's uploader. Publishing is permanent: a
version can be retracted or discontinued later, but never deleted or reused.

Consider creating a **verified publisher** (pub.dev, "Create publisher") and
moving the package to it: it shows a verified badge and lets several people
manage the package.

## 6. Check the score

Open `https://pub.dev/packages/image_color_backdrop/score` a few minutes after
publishing. The 160 points are:

| Category | Points | What it needs |
| --- | ---: | --- |
| Follow Dart file conventions | 30 | Valid pubspec, README, CHANGELOG, OSI license, repository, issue tracker. |
| Provide documentation | 20 | An example and enough dartdoc comments (this package documents its whole public API). |
| Platform support | 20 | Supports several platforms (all six here). |
| Pass static analysis | 50 | `flutter analyze` and formatting are clean. |
| Support up-to-date dependencies | 40 | Dependencies and SDK constraints are current. |

If "up-to-date dependencies" or "static analysis" shows a deduction after a
future Flutter release, raise `flutter_lints` and the SDK constraints and
publish a patch version.

## 7. Automated releases (optional)

`.github/workflows/publish.yaml` publishes from GitHub Actions when you push a
tag like `v0.1.0`, using pub.dev's OIDC integration (no secrets stored):

1. On pub.dev open the package, then Admin, Automated publishing.
2. Enable publishing from GitHub Actions, enter the repository
   `1shabbirhussain/image_color_backdrop`, and the tag pattern `v{{version}}`.
3. Bump `version:` in `pubspec.yaml`, update `CHANGELOG.md`, commit, then:

```sh
git tag v0.1.1
git push origin v0.1.1
```

## Releasing new versions

Use semantic versioning: patch (0.1.1) for fixes, minor (0.2.0) for
backwards-compatible features, and while the package is below 1.0.0 a minor
bump may contain breaking changes. Always add a matching section to
`CHANGELOG.md`.
