import Foundation
import FirebaseAuth

// TODO: Review

struct UserService {
    static let shared = UserService()
    
    private init() {}

    func getCurrentUser() async throws -> String? {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        guard let url = URL(string: "\(PropertiesService.shared.baseURL)/user/me") else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }

        guard httpResponse.statusCode != 401 else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        return userResponse.username
    }
    
    func setUsername(_ username: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        guard let url = URL(string: "\(PropertiesService.shared.baseURL)/user/me") else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = UserResponse(username: username)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set username"])
        }
    }
}

struct UserResponse: Codable {
    let username: String
}
