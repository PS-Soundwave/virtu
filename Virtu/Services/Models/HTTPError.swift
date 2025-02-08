enum HttpError : Error {
    case badRequest
    case unauthorized
    case conflict
    case serverError

    static func from(code: Int) -> HttpError {
        switch (code) {
        case 400:
            return .badRequest
        case 401:
            return .unauthorized
        case 409:
            return .conflict
        default:
            return .serverError
        }
    }

    static func guardStatusCode(code: Int) throws {
        guard code == 200 else {
            throw from(code: code)
        }
    }
}
