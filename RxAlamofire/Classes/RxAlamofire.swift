import Alamofire
import RxSwift
import RxCocoa

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
                    guard let httpUrlResponse = dataResponse.response else { throw NetworkingError.networkError(cause: dataResponse.error) }

                    if (loggingEnabled) {
                        print("Status Code: " + String(httpUrlResponse.statusCode))
                        print(String(data: dataResponse.data ?? Data(), encoding: .utf8) ?? "")
                    }

                    switch httpUrlResponse.statusCode {
                    case 400..<500:  throw NetworkingError.clientError(statusCode: httpUrlResponse.statusCode, body: dataResponse.data)
                    case 500..<600:  throw NetworkingError.serverError(statusCode: httpUrlResponse.statusCode)
                            //200..<300
                    default: return dataResponse
                    }
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
            guard let data = response.data else { throw NetworkingError.codingError(message: "No response data available!", cause: nil) }
            do {
                return try responseConverter.from(data: data)
            } catch let error as NetworkingError {
                throw error
            } catch {
                throw NetworkingError.codingError(message: "", cause: error)
            }
        }.do(onError: { e in print(e) })
    }

    public func decodeFromJson<R:Decodable>() -> Single<R> {
        return self.decodeWith(responseConverter: JsonResponseConverter())
    }

    public func emptyResponse() -> Single<Void> {
        return self.map { _ in }
    }
}

extension PrimitiveSequence where Trait == SingleTrait {

    public func asResponseEntityDriver() -> Driver<ResponseEntity<Element>> {
        return self.map { .success(data: $0) }.asDriver(onErrorRecover: { error in
            if let err = error as? NetworkingError {
                return Driver.just(.error(err))
            } else {
                return Driver.just(.error(NetworkingError.otherError(cause: error)))
            }
        })
    }
}

public func onlySuccessfulDataOf<T>(responses: Driver<ResponseEntity<T>>) -> Driver<T> {
    return responses.filter {
        switch $0 {
        case .success(_): return true
        default: return false
        }
    }.map {
        if case .success(let data) = $0 {
            return data
        } else {
            fatalError("Must not happen!")
        }
    }
}

public func onlyErrorsOf<T>(responses: Driver<ResponseEntity<T>>) -> Driver<NetworkingError> {
    return responses.filter {
        switch $0 {
        case .error(_): return true
        default: return false
        }
    }.map {
        if case .error(let error) = $0 {
            return error
        } else {
            fatalError("Must not happen!")
        }
    }
}
