import Foundation

struct Video : Codable, Identifiable {
    let id: String
    let key: String

    var streamURL: URL {
        return URL(string: "\(PropertiesService.shared.s3BaseURL)/\(key)")!
    }
}
