import AVKit
import PhotosUI
import SwiftUI

struct ContentView: View {
    // Create a video player with a sample video URL
    private let player = AVPlayer(
        url: Bundle.main.url(forResource: "placeholder", withExtension: "mp4") ?? URL(
            string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )!)

    @State private var isDrawerPresented = false
    @State private var showingPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingGallery = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Using AVPlayerViewController instead of VideoPlayer
                AVPlayerControllerRepresentable(player: player)

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
        }
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
        .background(Color.black)
        .foregroundColor(Color.white)
        .onAppear {
            player.play()
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
            // Handle the selected video here
            print("Video selected")
        }
        .fullScreenCover(isPresented: $showingGallery) {
            GalleryView()
        }
    }
}

// Wrapper to use AVPlayerViewController in SwiftUI
struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resize

        // Rotate the video layer 90 degrees
        if let layer = controller.view?.layer {
            layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 0, 1)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
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
