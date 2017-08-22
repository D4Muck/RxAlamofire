import Alamofire
import RxSwift

public class Test {

    public init() {
    }

    public func testIt() {
        print("Hello World!")
    }

    func requestInternal(url: String) -> Single<DefaultDataResponse> {
        return Single.create { observer in
            let request = Alamofire.request(url).response { response in
                observer(.success(response))
            }
            return Disposables.create { request.cancel() }
        }
    }

    public func request(url: String) {
        request(url: url).map { (response: DefaultDataResponse) in
            print("Na passt!")
        }
    }
}
