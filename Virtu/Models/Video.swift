import Foundation

struct Video: Codable, Identifiable {
    let key: String
    let created_at: String
    let id: String
    
    var streamURL: URL {
        return URL(string: "\(PropertiesService.shared.s3BaseURL)/\(key)")!
    }
}
