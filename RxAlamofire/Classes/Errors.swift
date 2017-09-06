//
// Created by Christoph Muck on 23/08/2017.
//

public enum NetworkingError: Error {
    case clientError(statusCode: Int, body: Data?)
    case serverError(statusCode: Int)
    case networkError(cause: Error?)
    case codingError(message: String, cause: Error?)
    case otherError(cause: Error)
}
