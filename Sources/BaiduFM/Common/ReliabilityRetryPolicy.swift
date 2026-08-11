import Foundation

nonisolated enum ReliabilityRetryPolicy {
    static let maximumRetryCount = 3

    private static let retryableStatusCodes: Set<Int> = [408, 425, 429, 500, 502, 503, 504]
    private static let retryableURLErrorCodes: Set<Int> = [
        URLError.timedOut.rawValue,
        URLError.cannotFindHost.rawValue,
        URLError.cannotConnectToHost.rawValue,
        URLError.networkConnectionLost.rawValue,
        URLError.dnsLookupFailed.rawValue,
        URLError.notConnectedToInternet.rawValue,
        URLError.internationalRoamingOff.rawValue,
        URLError.callIsActive.rawValue,
        URLError.dataNotAllowed.rawValue,
        URLError.resourceUnavailable.rawValue,
    ]

    static func shouldRetry(
        statusCode: Int? = nil,
        urlErrorCode: Int? = nil,
        attempt: Int,
        maximumRetryCount: Int = maximumRetryCount
    ) -> Bool {
        guard attempt < maximumRetryCount else { return false }
        if let statusCode, retryableStatusCodes.contains(statusCode) {
            return true
        }
        if let urlErrorCode, retryableURLErrorCodes.contains(urlErrorCode) {
            return true
        }
        return false
    }

    static func delay(forAttempt attempt: Int) -> TimeInterval {
        min(0.5 * pow(2, Double(max(attempt, 0))), 4)
    }
}
