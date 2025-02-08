import Foundation
import FirebaseAuth

struct UserService {
    static let shared = UserService()
    
    private init() {}

    func getCurrentUser() async throws -> User? {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw HttpError.unauthorized
        }
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/user/me")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        guard httpResponse.statusCode != 404 else {
            return nil
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)

        let user = try JSONDecoder().decode(User.self, from: data)

        return user
    }
    
    func patchUsername(_ username: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw HttpError.unauthorized
        }
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/user/me")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PutUserMeRequest(username: username)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }
        
        try HttpError.guardStatusCode(code: httpResponse.statusCode)
    }

    func searchUsers(_ query: String) async throws -> [User] {
        guard !query.isEmpty else { return [] }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/user/search?q=\(encodedQuery)")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)

        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    func getUserForUsername(_ username: String) async throws -> User? {
        let url = URL(string: "\(PropertiesService.shared.baseURL)/user?username=\(username)")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        guard httpResponse.statusCode != 404 else {
            return nil
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)

        let user = try JSONDecoder().decode(User.self, from: data)
        return user
    }

    func getVideos(userId: String) async throws -> [Video] {
        let url = URL(string: "\(PropertiesService.shared.baseURL)/user/\(userId)/video")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)

        let videos = try JSONDecoder().decode([Video].self, from: data)
        return videos
    }
}

struct PutUserMeRequest: Codable {
    let username: String
}
