import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth

struct VideoService {
    static let shared = VideoService()

    private init() {}

    func getVideos() async throws -> [Video] {
        let url = URL(string: "\(PropertiesService.shared.baseURL)/video")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)

        let videos = try JSONDecoder().decode([Video].self, from: data)
        return videos
    }

    func postVideo(fileURL: URL) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw HttpError.unauthorized
        }
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/video")!

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        var data = Data()
        let fileData = try Data(contentsOf: fileURL)
        let type = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"

        // Add file boundary
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(
                using: .utf8)!)
        data.append("Content-Type: \(type)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.serverError
        }

        try HttpError.guardStatusCode(code: httpResponse.statusCode)
    }
}
