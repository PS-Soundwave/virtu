import Foundation

struct PropertiesService {
    static let shared = PropertiesService()
    
    let baseURL: String
    let s3BaseURL: String
    
    private init() {
        guard
            let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            let s3BaseURL = Bundle.main.object(forInfoDictionaryKey: "S3BaseURL") as? String
        else {
            fatalError("APIBaseURL or S3BaseURL not configured in Info.plist")
        }
        
        self.baseURL = baseURL
        self.s3BaseURL = s3BaseURL
    }
}
