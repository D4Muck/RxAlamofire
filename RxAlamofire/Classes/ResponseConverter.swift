//
// Created by Christoph Muck on 23/08/2017.
//

public class ResponseConverter<R> {

    func from(data: Data) throws -> R {
        throw NetworkingError.codingError(message: "Method not overridden!", cause: nil)
    }
}

public class JsonResponseConverter<R:Decodable>: ResponseConverter<R> {

    public override func from(data: Data) throws -> R {
        return try JSONDecoder().decode(R.self, from: data)
    }
}
