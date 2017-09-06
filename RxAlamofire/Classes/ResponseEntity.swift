//
// Created by Christoph Muck on 06/09/2017.
//

import Foundation

public protocol ResponseEntityConvertible {
    associatedtype T

    func toResponseEntity() -> ResponseEntity<T>
}

public enum ResponseEntity<T> {
    case success(data: T)
    case error(_: NetworkingError)
}

extension ResponseEntity: ResponseEntityConvertible {
   public func toResponseEntity() -> ResponseEntity<T> {
        return self
    }
}
