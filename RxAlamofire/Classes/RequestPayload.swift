//
// Created by Christoph Muck on 23/08/2017.
//

import Alamofire

public protocol RequestPayload {
    func applyTo(urlRequest: inout URLRequest) throws
}

public class CompositePayload: RequestPayload {

    let payloads: [RequestPayload]

    public init(payloads: [RequestPayload]) {
        self.payloads = payloads
    }

    public func applyTo(urlRequest: inout URLRequest) throws {
        try payloads.forEach { try $0.applyTo(urlRequest: &urlRequest) }
    }
}

public class JsonRequestBody<N:Encodable>: RequestPayload {

    private let payload: N

    public init(payload: N) {
        self.payload = payload
    }

    public func applyTo(urlRequest: inout URLRequest) throws {
        let data = try JSONEncoder().encode(self.payload)
        urlRequest.httpBody = data

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

public class QueryParams: RequestPayload {

    private let payload: [String: String]

    private let escape = URLEncoding.queryString.escape

    private var query: String {
        return payload.map { escape($0.0) + "=" + escape($0.1) }.joined(separator: "&")
    }

    public init(_ payload: [String: String]) {
        self.payload = payload
    }

    public func applyTo(urlRequest: inout URLRequest) throws {
        guard let url = urlRequest.url else { throw RxAlError.urlMissingError }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + self.query
            urlComponents.percentEncodedQuery = percentEncodedQuery
            urlRequest.url = urlComponents.url
        }
    }
}

public class EmptyRequestPayload: RequestPayload {

    public init() {
    }

    public func applyTo(urlRequest: inout URLRequest) throws {
    }
}
