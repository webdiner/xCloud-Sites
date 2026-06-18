# xCloud Sites

A tiny **native macOS (Apple Silicon)** app that lists every site on your
[xCloud](https://xcloud.host) account and gives each one a one-click **Magic Login**
button — a passwordless `/wp-admin` session that opens in your browser.

Inspired by [xCloud-Pulse](https://github.com/xCloudDev/xCloud-Pulse), but pared down
to just: **search box at the top + site list + magic login.**

## Features

- Lists all sites across all your servers (paginates the API automatically).
- Instant client-side **search** by domain or title.
- **Magic Login** button per WordPress site → opens a 10-minute passwordless
  wp-admin URL in your default browser.
- API token stored securely in the **macOS Keychain** (never written to disk in plain text).
- Status dot per site (active / provisioning / failed / inactive).

## Requirements

- Apple Silicon Mac (M1 or newer), macOS 14+.
- Swift toolchain (ships with Xcode **or** the Command Line Tools — `xcode-select --install`).
- An xCloud **API token**: xCloud dashboard → Settings → API Tokens → *Create New Token*.
  - `read` scope is enough to list sites; `write` scope is required for Magic Login.

## Build & run

```bash
./build.sh
open "dist/xCloud Sites.app"
```

`build.sh` compiles a release `arm64` binary, assembles `dist/xCloud Sites.app`, and
ad-hoc code-signs it so it launches without Gatekeeper complaints.

On first launch, click **Add API Token…**, paste your token, and Save. The site list
loads immediately. Use the search box up top to filter, and **Magic Login** to jump
into any WordPress site's dashboard.

## API used

| What | Call |
|---|---|
| Base URL | `https://app.xcloud.host/api/v1` |
| Auth | `Authorization: Bearer <token>` |
| List sites | `GET /sites?per_page=100&page=N` |
| Magic login | `POST /sites/{uuid}/magic-login` → `data.url` |

## Project layout

```
Package.swift                  SPM executable target (macOS 14+)
Sources/xCloudSites/
  App.swift                    @main SwiftUI app + WindowGroup
  AppState.swift               ObservableObject: token, sites, search, magic-login
  APIClient.swift              xCloud REST client (sites + magic-login)
  Models.swift                 Codable models + API envelopes
  Keychain.swift               token storage in the macOS Keychain
  Views/RootView.swift         onboarding vs. site list
  Views/SitesView.swift        search bar, list, rows, magic-login button
  Views/SettingsView.swift     token entry sheet
Resources/Info.plist           bundle metadata template
build.sh                       compile + assemble + sign the .app
```

## License

[MIT](LICENSE).

> Unofficial third-party client. Not affiliated with xCloud.
