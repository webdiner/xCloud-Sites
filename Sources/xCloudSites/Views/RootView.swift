import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings {
                SettingsView(onClose: { showSettings = false })
            } else if state.hasToken {
                SitesView(showSettings: $showSettings)
            } else {
                OnboardingView(showSettings: $showSettings)
            }
        }
        .task {
            if state.hasToken && state.sites.isEmpty {
                await state.loadSites()
            }
        }
    }
}

struct OnboardingView: View {
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "cloud.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.accentColor)
            Text("Welcome to xCloud Sites")
                .font(.headline)
            Text("Paste your xCloud API token to load your sites and use one-click magic login.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Add API Token…") { showSettings = true }
                .buttonStyle(.borderedProminent)
            Link("Where do I find my token?",
                 destination: URL(string: "https://xcloud.host/docs/how-to-access-the-xcloud-api/")!)
                .font(.caption2)
            Spacer()
            FooterBar(count: nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shared footer with the site count and a Quit button (menu-bar apps need an explicit quit).
struct FooterBar: View {
    let count: Int?

    var body: some View {
        Divider()
        HStack {
            if let count {
                Text("\(count) site\(count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
