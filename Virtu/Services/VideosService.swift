import SwiftUI

struct VideoService {
    static let shared = VideoService()

    private init() {}

    func getVideos() async throws -> [Video] {
        let url = URL(string: "\(PropertiesService.shared.baseURL)/videos")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(VideoResponse.self, from: data)
        return response.videos
    }
}
