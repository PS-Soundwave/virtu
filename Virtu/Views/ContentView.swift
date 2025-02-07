import SwiftUI
import PhotosUI

// TODO: Review

// Model for video data from API
struct Video: Codable, Identifiable {
    let key: String
    let created_at: String
    let id: String
    
    var streamURL: URL {
        guard let s3BaseURL = Bundle.main.object(forInfoDictionaryKey: "S3BaseURL") as? String else {
            fatalError("S3BaseURL not found in Info.plist")
        }

        return URL(string: "\(s3BaseURL)/\(key)")!
    }
}

// View model to fetch and manage videos
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    let baseURL: String

    init() {
        guard
            let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        else {
            fatalError("APIBaseURL not configured in Info.plist")
        }
        
        self.baseURL = baseURL
    }
    
    func fetchVideos() async {
        do {
            let url = URL(string: "\(baseURL)/videos")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(VideoResponse.self, from: data)
            
            await MainActor.run {
                self.videos = response.videos
            }
        } catch {
            print("Error fetching videos: \(error)")
        }
    }
}

// Response type for the API
struct VideoResponse: Codable {
    let videos: [Video]
}

// Main content view with vertical scroll
struct ContentView: View {
    @StateObject private var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0
    @State private var showingGallery = false
    @State private var showingPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var uploadError: Error?
    
    var body: some View {
            VStack {
                ZStack {
                    if isUploading {
                        ProgressView("Uploading...")
                    }
                    GeometryReader { geometry in 
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.videos) { video in
                                    VideoPlayerView(video: video).frame(width: geometry.size.width, height: geometry.size.height)
                                }
                        }.scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    }
                }
                
                HStack(alignment: .center, spacing: 20) {
                    Button(action: {
                        showingGallery = true
                    }) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 30))
                    }

                    Menu {
                        Button(action: {
                            // Handle OBS recording option
                            print("Record from OBS tapped")
                        }) {
                            Label("Record from OBS", systemImage: "record.circle")
                        }
                        
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            Label("Upload Video", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 30))
                    }
                }
            }
            .ignoresSafeArea(edges: [.top, .leading, .trailing])
            .task {
                await viewModel.fetchVideos()
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedItems,
                maxSelectionCount: 1,
                matching: .videos,
                preferredItemEncoding: .current
            )
            .onChange(of: selectedItems) { prev, items in
                guard let item = items.first else { return }
                item.loadTransferable(
                    type: VideoPickerTransferable.self
                ) { result in
                    guard let videoData = try? result.get() else { return }
                    Task {
                        await uploadVideo(url: videoData.url)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func uploadVideo(url: URL) async {
        isUploading = true
        defer { isUploading = false }

        do {
            defer {
                try? FileManager.default.removeItem(at: url)
            }

            // Now upload the local copy
            try await UploadService.shared.uploadVideo(fileURL: url)
            print("Upload completed")
        } catch {
            print(error)
            self.uploadError = error
        }
    }
}

// Add this to handle video data from PhotosPicker
struct VideoPickerTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { received in
            SentTransferredFile(received.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent(
                received.file.lastPathComponent)
            
            try? FileManager.default.removeItem(at: dest)

            try FileManager.default.copyItem(at: received.file, to: dest)
            
            return Self(url: dest)
        }
    }
}
