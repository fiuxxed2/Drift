# Drift

Focus timer for iPhone (SwiftUI, iOS 17+).

## Get the .ipa (no Mac needed)

1. Create a GitHub repo and upload everything in this folder (keep the `.github` folder).
2. Open the **Actions** tab. The build runs automatically (or click **Run workflow**).
3. When it finishes, download the **Drift-ipa** artifact and unzip it to get `Drift.ipa`.
4. Sideload `Drift.ipa` with your tool. It is unsigned, so your sideloader signs it.

## On a Mac

`brew install xcodegen && xcodegen generate`, then open `Drift.xcodeproj`.
