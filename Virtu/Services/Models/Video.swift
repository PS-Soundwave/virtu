import Foundation

struct Video : Codable, Identifiable {
    let id: String
    let key: String
    let thumbnail_key: String

    var streamURL: URL {
        return URL(string: "\(PropertiesService.shared.s3BaseURL)/\(key)")!
    }

    var thumbnailURL: URL {
        return URL(string: "\(PropertiesService.shared.s3BaseURL)/\(thumbnail_key)")!
    }
}
