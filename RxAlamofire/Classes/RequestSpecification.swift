//
// Created by Christoph Muck on 23/08/2017.
//

import Alamofire

public struct RequestSpecification {
    let path: String
    let method: HTTPMethod
    let payload: RequestPayload

    public init(
            path: String,
            method: HTTPMethod,
            payload: RequestPayload = EmptyRequestPayload()
    ) {
        self.path = path
        self.method = method
        self.payload = payload
    }
}
