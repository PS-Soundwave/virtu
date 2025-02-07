import Foundation

// TODO: Review

struct UserSearchResponse: Codable {
    let suggestions: [String]
}

// TODO: Review

struct UserSearchService {
    static let shared = UserSearchService()
    
    private init() {}

    func searchUsers(query: String) async throws -> [String] {
        guard !query.isEmpty else { return [] }
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/users/search?q=\(encodedQuery)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(UserSearchResponse.self, from: data)
        return response.suggestions
    }
    
    func validateUsername(_ username: String) async throws -> Bool {
        let url = URL(string: "\(PropertiesService.shared.baseURL)/users/validate?username=\(username)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: Bool].self, from: data)
        return response["exists"] ?? false
    }
}
