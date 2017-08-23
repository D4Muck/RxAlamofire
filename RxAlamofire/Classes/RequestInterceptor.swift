//
// Created by Christoph Muck on 23/08/2017.
//

public protocol RequestInterceptor {
    func intercept(urlRequest: inout URLRequest)
}

public protocol HeaderAddingRequestInterceptor: RequestInterceptor {
    var additionalHeaders: [String: String] { get }
}

extension HeaderAddingRequestInterceptor {
    public func intercept(urlRequest: inout URLRequest) {
        additionalHeaders.forEach { urlRequest.addValue($0.1, forHTTPHeaderField: $0.0) }
    }
}

public enum HttpAuthorization: HeaderAddingRequestInterceptor {
    case basic(user: String, password: String)
    case bearerAccessToken(accessTokenProvider: AccessTokenProvider)

    public var additionalHeaders: [String: String] {
        let headerValue: String
        switch self {
        case let .basic(user, password):
            headerValue = "Basic " + Data((user + ":" + password).utf8).base64EncodedString()
        case let .bearerAccessToken(accessTokenProvider):
            headerValue = "Bearer " + accessTokenProvider.accessToken
        }
        return ["Authorization": headerValue]
    }
}

public protocol AccessTokenProvider {
    var accessToken: String { get }
}
