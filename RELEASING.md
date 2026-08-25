# Releasing MarkView

## GitHub release (DMG)

```bash
./make-dmg.sh
gh release create vX.Y.Z MarkView-X.Y.Z.dmg --title "MarkView X.Y.Z" --notes "..."
```

The DMG is ad-hoc signed. Users must right-click → Open on first launch, or
`xattr -d com.apple.quarantine`. To remove that friction, notarize (below).

## Notarized direct distribution (removes Gatekeeper warning)

Requires Apple Developer Program membership ($99/year).

1. In Xcode → Settings → Accounts, create a **Developer ID Application** certificate.
2. Sign with hardened runtime and notarize:

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: LEE SINSEONG (TEAMID)" MarkView.app
xcrun notarytool submit MarkView-X.Y.Z.dmg \
  --apple-id you@example.com --team-id TEAMID \
  --password <app-specific-password> --wait
xcrun stapler staple MarkView-X.Y.Z.dmg
```

## Mac App Store

Current status: an **Apple Development** certificate exists on this machine.
App Store submission additionally requires:

1. **Apple Developer Program membership** (paid) with an
   **Apple Distribution** certificate and a **Mac App Store provisioning profile**
   for `com.seeeeeeong.markview` (create both in Xcode or developer.apple.com).
2. **App Sandbox** — mandatory. `MarkView.entitlements` is prepared
   (sandbox + user-selected read-only files + network client for remote images).
   Before submitting, one code change is required: in
   `Sources/MarkView/Rendering/RendererView.swift`, `loadFileURL` currently
   grants read access to `/`; under sandbox, grant access to the opened
   document's directory instead (pass it from the render request), because the
   sandbox only allows user-selected files.
3. Sign and package:

```bash
codesign --force --deep --options runtime \
  --entitlements MarkView.entitlements \
  --sign "Apple Distribution: LEE SINSEONG (TEAMID)" MarkView.app
productbuild --component MarkView.app /Applications \
  --sign "3rd Party Mac Developer Installer: LEE SINSEONG (TEAMID)" MarkView.pkg
```

4. Create the app record in **App Store Connect** (name, bundle id
   `com.seeeeeeong.markview`, category Productivity), upload with
   `xcrun altool --upload-package` or Transporter.app, fill in screenshots
   (1280x800 or 2560x1600), description, privacy declaration
   (no data collected), and submit for review.

Review notes: the app is a viewer only, loads no analytics, and the bundled
rendering engine is offline; remote images are the only network access.
