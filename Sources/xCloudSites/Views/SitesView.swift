import SwiftUI

struct SitesView: View {
    @EnvironmentObject var state: AppState
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            FooterBar(count: state.sites.isEmpty ? nil : state.sites.count)
        }
        .alert("Magic login failed",
               isPresented: Binding(get: { state.loginError != nil },
                                    set: { if !$0 { state.loginError = nil } })) {
            Button("OK", role: .cancel) { state.loginError = nil }
        } message: {
            Text(state.loginError ?? "")
        }
        .alert("Cache purge failed",
               isPresented: Binding(get: { state.cacheError != nil },
                                    set: { if !$0 { state.cacheError = nil } })) {
            Button("OK", role: .cancel) { state.cacheError = nil }
        } message: {
            Text(state.cacheError ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Search sites…", text: $state.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !state.query.isEmpty {
                    Button { state.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))

            Button {
                Task { await state.loadSites() }
            } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .disabled(state.isLoading)
            .help("Reload sites")

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape").font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if state.isLoading && state.sites.isEmpty {
            VStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Loading sites…").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = state.loadError {
            ErrorState(message: err) { Task { await state.loadSites() } }
        } else if state.filteredSites.isEmpty {
            let empty = state.sites.isEmpty ? "No sites found on this account."
                                            : "No sites match “\(state.query)”."
            Text(empty)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.filteredSites) { site in
                        SiteRow(site: site)
                            .environmentObject(state)
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }
}

struct SiteRow: View {
    @EnvironmentObject var state: AppState
    let site: Site
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 9) {
            StatusDot(status: site.status, readable: site.status_readable)

            Button {
                if let url = site.siteURL { NSWorkspace.shared.open(url) }
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(site.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .underline(hovering)
                        .lineLimit(1)
                    if let subtitle = site.subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if !site.isWordPress {
                        Text(site.type)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(site.siteURL == nil)
            .help(site.siteURL.map { "Open \($0.absoluteString)" } ?? "")
            .onHover { inside in
                hovering = inside && site.siteURL != nil
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }

            if site.isWordPress {
                cacheButton
                magicLoginButton
            } else {
                Text("Not WP")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var cacheButton: some View {
        let busy = state.clearingCache.contains(site.uuid)
        let done = state.cacheCleared.contains(site.uuid)
        Button {
            Task { await state.clearCache(site) }
        } label: {
            Group {
                if busy {
                    ProgressView().controlSize(.mini)
                } else if done {
                    Image(systemName: "checkmark").foregroundStyle(.green)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .font(.system(size: 11))
            .frame(width: 20, height: 15)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(busy)
        .help("Clear this site's cache (full-page + object caches)")
    }

    @ViewBuilder
    private var magicLoginButton: some View {
        let busy = state.loggingIn.contains(site.uuid)
        Button {
            Task { await state.magicLogin(site) }
        } label: {
            HStack(spacing: 4) {
                if busy {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "wand.and.stars").font(.system(size: 10))
                }
                Text("Magic Login").font(.system(size: 11))
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(busy)
        .help("Open a passwordless wp-admin session in your browser")
    }
}

struct StatusDot: View {
    let status: String
    var readable: String? = nil

    private var color: Color {
        switch status.lowercased() {
        case "active", "provisioned", "live", "running", "online": return .green
        case "provisioning", "pending", "deploying": return .orange
        case "failed", "error", "offline", "suspended": return .red
        default: return .gray
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .help(readable ?? status.capitalized)
    }
}

struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Button("Try Again", action: retry)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
