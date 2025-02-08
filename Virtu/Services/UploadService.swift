import FirebaseAuth
import Foundation
import UniformTypeIdentifiers

enum UploadError: Error {
    case error(Int)
    case unauthorized
}

struct UploadService {
    static let shared = UploadService()

    private init() {}

    func uploadVideo(fileURL: URL) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw UploadError.unauthorized
        }
        
        let url = URL(string: "\(PropertiesService.shared.baseURL)/upload")!

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

        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            throw UploadError.error(httpResponse.statusCode)
        }
    }
}
