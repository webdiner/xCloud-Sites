import Foundation

// MARK: - API envelopes

struct SuccessEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T
}

struct ErrorEnvelope: Decodable {
    let success: Bool?
    let message: String?
}

struct PageMeta: Decodable {
    let current_page: Int
    let last_page: Int
    let per_page: Int
    let total: Int
}

struct PaginatedSites: Decodable {
    let items: [Site]
    let pagination: PageMeta
}

// MARK: - Domain models

struct Site: Decodable, Identifiable, Hashable {
    let uuid: String
    let name: String
    let domain_name: String?
    let type: String
    let status: String
    let status_readable: String?
    let php_version: String?
    let server_uuid: String?
    let created_at: String?

    var id: String { uuid }

    /// Primary label: the site's name.
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? (domain_name ?? uuid) : trimmed
    }

    /// Secondary label: the domain, when it differs from the name.
    var subtitle: String? {
        guard let domain = domain_name?.trimmingCharacters(in: .whitespaces),
              !domain.isEmpty, domain != displayName else { return nil }
        return domain
    }

    var isWordPress: Bool { type.lowercased() == "wordpress" }

    /// The public URL of the site, derived from its domain (or name).
    var siteURL: URL? {
        let host = (domain_name?.trimmingCharacters(in: .whitespaces).nilIfEmpty) ?? name
        let trimmed = host.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct MagicLoginResult: Decodable {
    let url: String
    let expires_at: String?
    let admin_user: String?
}
