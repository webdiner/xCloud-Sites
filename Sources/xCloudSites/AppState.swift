import Foundation
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var token: String = ""
    @Published var sites: [Site] = []
    @Published var query: String = ""
    @Published var isLoading = false
    @Published var loadError: String?

    /// UUIDs of sites whose magic-login link is currently being fetched.
    @Published var loggingIn: Set<String> = []
    /// Transient error shown after a failed magic-login attempt.
    @Published var loginError: String?

    var hasToken: Bool { !token.isEmpty }

    init() {
        token = Keychain.load() ?? ""
    }

    var filteredSites: [Site] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sites }
        return sites.filter {
            $0.name.lowercased().contains(q) ||
            ($0.domain_name?.lowercased().contains(q) ?? false)
        }
    }

    func saveToken(_ newToken: String) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        token = trimmed
        if trimmed.isEmpty {
            Keychain.delete()
            sites = []
        } else {
            Keychain.save(trimmed)
        }
    }

    func clearToken() {
        Keychain.delete()
        token = ""
        sites = []
        loadError = nil
    }

    func loadSites() async {
        guard hasToken else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let fetched = try await APIClient(token: token).fetchAllSites()
            sites = fetched.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        } catch {
            loadError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func magicLogin(_ site: Site) async {
        guard !loggingIn.contains(site.uuid) else { return }
        loggingIn.insert(site.uuid)
        loginError = nil
        defer { loggingIn.remove(site.uuid) }
        do {
            let url = try await APIClient(token: token).magicLoginURL(siteUUID: site.uuid)
            NSWorkspace.shared.open(url)
        } catch {
            loginError = "\(site.displayName): " +
                ((error as? APIError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
