import Foundation

enum APIError: LocalizedError {
    case noToken
    case unauthorized
    case http(status: Int, message: String)
    case decoding(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No API token set. Add one in Settings."
        case .unauthorized:
            return "Token rejected (401). Check the token in Settings."
        case .http(let status, let message):
            return "Request failed (\(status)): \(message)"
        case .decoding(let detail):
            return "Couldn't read the server response: \(detail)"
        case .network(let detail):
            return "Network error: \(detail)"
        }
    }
}

/// Talks to the xCloud public REST API (https://app.xcloud.host/api/v1).
struct APIClient {
    let token: String
    private let base = URL(string: "https://app.xcloud.host/api/v1")!
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    // MARK: Requests

    private func makeRequest(_ method: String, _ path: String,
                             query: [URLQueryItem] = [],
                             body: Data? = nil) -> URLRequest {
        var components = URLComponents(url: base.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    private func send(_ req: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.network("No HTTP response")
        }
        switch http.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        default:
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw APIError.http(status: http.statusCode, message: message)
        }
    }

    // MARK: Endpoints

    /// Fetches every site across all pages (per_page maxes out at 100 server-side).
    func fetchAllSites() async throws -> [Site] {
        var all: [Site] = []
        var page = 1
        while true {
            let req = makeRequest("GET", "sites", query: [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: String(page))
            ])
            let data = try await send(req)
            let envelope: SuccessEnvelope<PaginatedSites>
            do {
                envelope = try JSONDecoder().decode(SuccessEnvelope<PaginatedSites>.self, from: data)
            } catch {
                throw APIError.decoding(String(describing: error))
            }
            all.append(contentsOf: envelope.data.items)
            if page >= envelope.data.pagination.last_page { break }
            page += 1
            if page > 100 { break } // hard safety stop
        }
        return all
    }

    /// Generates a short-lived passwordless wp-admin login URL for a WordPress site.
    func magicLoginURL(siteUUID: String) async throws -> URL {
        let req = makeRequest("POST", "sites/\(siteUUID)/magic-login", body: Data("{}".utf8))
        let data = try await send(req)
        let envelope: SuccessEnvelope<MagicLoginResult>
        do {
            envelope = try JSONDecoder().decode(SuccessEnvelope<MagicLoginResult>.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
        guard let url = URL(string: envelope.data.url) else {
            throw APIError.decoding("Malformed login URL")
        }
        return url
    }

    /// Clears the site's caches: full-page (LiteSpeed) + object/Redis/Cloudflare-edge.
    /// Both endpoints return 202; a failure on either is surfaced to the caller.
    func purgeCache(siteUUID: String) async throws {
        _ = try await send(makeRequest("POST", "sites/\(siteUUID)/cache/purge", body: Data("{}".utf8)))
        _ = try await send(makeRequest("POST", "sites/\(siteUUID)/cache/purge-all", body: Data("{}".utf8)))
    }
}
