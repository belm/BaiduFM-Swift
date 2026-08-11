import Foundation

enum APIConfigurationError: Error, LocalizedError, Equatable {
    case invalidBaseURL
    case insecureTransport
    case invalidEndpoint

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return L10n.invalidAPIConfiguration
        case .insecureTransport:
            return L10n.insecureConnectionBlocked
        case .invalidEndpoint:
            return L10n.invalidURL
        }
    }
}

struct APIConfiguration: Sendable, Equatable {
    static let infoPlistKey = "BaiduFMAPIBaseURL"
    static let environmentKey = "BAIDUFM_API_BASE_URL"

    let baseURL: URL

    init(baseURL: URL) throws {
        guard baseURL.scheme?.lowercased() == "https", baseURL.host != nil else {
            throw baseURL.scheme?.lowercased() == "http"
                ? APIConfigurationError.insecureTransport
                : APIConfigurationError.invalidBaseURL
        }
        self.baseURL = baseURL
    }

    init(baseURLString: String) throws {
        guard let url = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw APIConfigurationError.invalidBaseURL
        }
        try self.init(baseURL: url)
    }

    static func resolved(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> APIConfiguration {
        let configuredValue = environment[environmentKey]
            ?? bundle.object(forInfoDictionaryKey: infoPlistKey) as? String

        if let configuredValue, let configuration = try? APIConfiguration(baseURLString: configuredValue) {
            return configuration
        }

        guard let fallback = try? APIConfiguration(baseURLString: "https://fm.baidu.com") else {
            preconditionFailure("The built-in API URL must be a valid HTTPS URL.")
        }
        return fallback
    }

    func endpoint(queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIConfigurationError.invalidEndpoint
        }
        var path = components.path
        if !path.hasSuffix("/") {
            path.append("/")
        }
        components.path = path + "dev/api/"
        components.queryItems = queryItems
        guard let url = components.url else {
            throw APIConfigurationError.invalidEndpoint
        }
        return url
    }

    func secureContentURL(from value: String) -> URL? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty,
              let url = URL(string: trimmedValue, relativeTo: baseURL)?.absoluteURL,
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }
        return url
    }
}
