import Foundation

enum UploadError: Error {
    case invalidResponse
    case uploadFailed(String)
    case invalidURL
    case missingConfiguration
}

// TODO: Review

struct UploadService {
    static let shared = UploadService()

    private init() {}

    func uploadVideo(fileURL: URL) async throws {
        guard let url = URL(string: "\(PropertiesService.shared.baseURL)/upload") else {
            throw UploadError.invalidURL
        }

        // Generate a unique key for this upload
        let key = UUID().uuidString

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create multipart form data
        var data = Data()
        let fileData = try Data(contentsOf: fileURL)

        // Add file boundary
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(key).mp4\"\r\n".data(
                using: .utf8)!)
        data.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        print("Sending data: \(data)")

        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        print("Sent")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UploadError.uploadFailed(
                "Upload failed with status code: \(httpResponse.statusCode)")
        }
    }
}
