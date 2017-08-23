import Alamofire
import RxSwift

let loggingEnabled = true

public class RequestMakerFactory {

    private let baseUrl: String

    public init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    public func createInstance(
            withPathPrefix pathPrefix: String = "",
            andRequestInterceptors requestInterceptors: [RequestInterceptor] = []
    ) -> RequestMaker {
        return RequestMaker(baseUrl: self.baseUrl + pathPrefix, requestInterceptors: requestInterceptors)
    }
}

public class RequestMaker {

    let baseUrl: String
    let requestInterceptors: [RequestInterceptor]

    init(baseUrl: String, requestInterceptors: [RequestInterceptor]) {
        self.baseUrl = baseUrl
        self.requestInterceptors = requestInterceptors
    }

    private func requestInternal(urlRequest: URLRequest) -> Single<DefaultDataResponse> {
        log(urlRequest: urlRequest)
        return Single.create { observer in
            let request = Alamofire.request(urlRequest).response { response in
                observer(.success(response))
            }
            return Disposables.create { request.cancel() }
        }
    }

    public func request(_ spec: RequestSpecification) -> Single<DefaultDataResponse> {
        return Single.deferred { [baseUrl = self.baseUrl, requestInterceptors = self.requestInterceptors] in
                    let url = baseUrl + spec.path
                    var urlRequest = try URLRequest(url: url, method: spec.method)
                    try spec.payload.applyTo(urlRequest: &urlRequest)
                    requestInterceptors.forEach { $0.intercept(urlRequest: &urlRequest) }
                    return Single.just(urlRequest)
                }
                .flatMap(requestInternal)
                .map { (dataResponse: DefaultDataResponse) -> DefaultDataResponse in
                    guard let httpUrlResponse = dataResponse.response else { throw RxAlError.epicFailError }

                    print(String(data: dataResponse.data ?? Data(), encoding: .utf8) ?? "")

                    if (200..<300 ~= httpUrlResponse.statusCode) {
                        return dataResponse
                    }

                    throw RxAlError.requestError(statusCode: httpUrlResponse.statusCode)
                }
    }

    private func log(urlRequest: URLRequest) {
        if (loggingEnabled) {
            print("------------------------------------REQUEST------------------------------------")
            print("URL   : " + (urlRequest.url?.description ?? ""))
            print("METHOD: " + (urlRequest.httpMethod ?? ""))
            print("HEADER: " + (urlRequest.allHTTPHeaderFields?.description ?? ""))
            print("BODY  : " + (String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""))
            print("-------------------------------------------------------------------------------")
        }
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == DefaultDataResponse {

    public func decodeWith<R>(responseConverter: ResponseConverter<R>) -> Single<R> {
        return self.map { (response: DefaultDataResponse) -> R in
            guard let data = response.data else { throw RxAlError.noResponseBodyError }
            return try responseConverter.from(data: data)
        }
    }

    public func decodeFromJson<R:Decodable>() -> Single<R> {
        return self.decodeWith(responseConverter: JsonResponseConverter())
    }

    public func emptyResponse() -> Single<Void> {
        return self.map { _ in }
    }
}
