//
// Created by Christoph Muck on 23/08/2017.
//

enum RxAlError: Error {
    case urlMissingError
    case noResponseBodyError
    case epicFailError
    case requestError(statusCode: Int)
}
