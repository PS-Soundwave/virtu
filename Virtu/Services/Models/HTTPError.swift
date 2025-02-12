enum HttpError : Error {
    case badRequest
    case unauthorized
    case notFound
    case conflict
    case serverError

    static func from(code: Int) -> HttpError {
        switch (code) {
        case 400:
            return .badRequest
        case 401:
            return .unauthorized
        case 404:
            return .notFound
        case 409:
            return .conflict
        default:
            return .serverError
        }
    }

    static func guardStatusCode(code: Int) throws {
        guard code == 200 || code == 201 else {
            throw from(code: code)
        }
    }
}
