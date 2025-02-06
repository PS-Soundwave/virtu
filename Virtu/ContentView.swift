import AVKit
import PhotosUI
import SwiftUI

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

// Custom video player view that handles HLS streams
struct VideoPlayerView: View {
    let video: Video
    var body: some View {
        let player = AVPlayer(url: video.streamURL)
        AVPlayerControllerRepresentable(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
        .task {
            /*print("Starting to create player for URL: \(video.streamURL)")
            
            // Create an asset and observe its loading status
            let asset = AVURLAsset(url: video.streamURL)
            do {
                try await asset.load(.tracks)
                try await asset.load(.duration)
                let isPlayable = try await asset.load(.isPlayable)
                print("Asset isPlayable: \(isPlayable) for \(video.streamURL)")
                
                // Only create the player if the asset is playable
                if isPlayable {
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    // Wait for the player item to become ready
                    try await withCheckedThrowingContinuation { continuation in
                        var observation: NSKeyValueObservation?
                        observation = playerItem.observe(\.status, options: [.new, .initial]) { item, _ in
                            print("Player item status changed to: \(item.status.rawValue)")
                            switch item.status {
                            case .readyToPlay:
                                continuation.resume()
                                observation?.invalidate()
                            case .failed:
                                continuation.resume(throwing: item.error ?? NSError(domain: "", code: -1))
                                observation?.invalidate()
                            default:
                                break
                            }
                        }
                    }
                    
                    let player = AVPlayer(playerItem: playerItem)
                    player.actionAtItemEnd = .none
                    
                    // Add observers for player status
                    let _ = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { time in
                        print("Player time update for \(video.streamURL): \(time.seconds)")
                    }
                    
                    player.automaticallyWaitsToMinimizeStalling = false
                    self.player = player
                    print("Player setup complete for \(video.streamURL)")
                    
                    // Start playback immediately
                    player.play()
                } else {
                    print("Asset is not playable for \(video.streamURL)")
                }
            } catch {
                print("Failed to load asset: \(error) for \(video.streamURL)")
                playerError = error
            }*/
        }
    }
}

// Custom AVPlayerController for better control
struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resize

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
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

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss

    struct VideoItem: Identifiable {
        let id = UUID()
        let thumbnailName: String
        let title: String
    }

    // Sample data - replace with real data later
    private let videos = [
        VideoItem(thumbnailName: "video.fill", title: "Video 1"),
        VideoItem(thumbnailName: "video.fill", title: "Video 2"),
        VideoItem(thumbnailName: "video.fill", title: "Video 3"),
        // Add more sample items as needed
    ]
    
    var body: some View {
            ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.title2)
                            .bold()
                        Text("Bio description goes here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Video Grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                    ], spacing: 2
                ) {
                    ForEach(videos) { video in
                        VideoThumbnail(video: video)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct VideoThumbnail: View {
    let video: GalleryView.VideoItem

    var body: some View {
        GeometryReader { geometry in
            Image(systemName: video.thumbnailName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
                .background(Color.gray.opacity(0.3))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ContentView()
}
