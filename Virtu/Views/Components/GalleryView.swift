import SwiftUI

// TODO: Review
struct GalleryView: View {
    let user: Binding<User?>
    @State private var videos: [Video] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedVideo: Video?

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
                        Text(user.wrappedValue?.username ?? "")
                            .font(.title2)
                            .bold()
                        Text("Bio description goes here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Failed to load videos: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else {
                    // Video Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                        ], spacing: 2
                    ) {
                        ForEach(videos) { video in
                            GeometryReader { geometry in
                                VideoThumbnail(video: video)
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .clipped()
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                selectedVideo = video
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            await loadVideos()
        }
        .fullScreenCover(item: $selectedVideo) { video in
            VideoPlayerView(video: video, isFullScreen: true)
        }
    }
    
    private func loadVideos() async {
        guard let userId = user.wrappedValue?.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            videos = try await UserService.shared.getVideos(userId: userId)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct VideoThumbnail: View {
    let video: Video

    var body: some View {
        AsyncImage(url: video.thumbnailURL) { phase in
            switch phase {
            case .empty:
                Color.gray
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            case .failure:
                Color.gray
                    .overlay {
                        Image(systemName: "video.slash.fill")
                            .foregroundStyle(.white)
                    }
            @unknown default:
                Color.gray
            }
        }
    }
}

#Preview {
    ContentView()
}
