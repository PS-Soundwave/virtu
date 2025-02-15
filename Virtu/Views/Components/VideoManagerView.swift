import SwiftUI

struct VideoManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var videos: [Video] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedVideo: Video?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(videos, id: \.id) { video in
                            VideoManagerThumbnail(video: video, onVisibilityToggle: { visibility in
                                Task {
                                    await updateVideoVisibility(video: video, visibility: visibility)
                                }
                            }, onTap: {
                                selectedVideo = video
                            })
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Videos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadVideos()
            }
            .fullScreenCover(item: $selectedVideo) { video in
                VideoPlayerView(video: video, isFullScreen: true)
            }
        }
    }
    
    private func loadVideos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            videos = try await VideoService.shared.getUserVideos()
        } catch {
            print(error)
            self.error = error
        }
    }
    
    private func updateVideoVisibility(video: Video, visibility: String) async {
        do {
            try await VideoService.shared.updateVideoVisibility(videoId: video.id, visibility: visibility)
            
            if let index = videos.firstIndex(where: { $0.id == video.id }) {
                videos[index] = Video(
                    id: video.id,
                    key: video.key,
                    thumbnail_key: video.thumbnail_key,
                    visibility: visibility
                )
            }
        } catch {
            self.error = error
        }
    }
}

struct VideoManagerThumbnail: View {
    let video: Video
    let onVisibilityToggle: (String) -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button(action: onTap) {
                AsyncImage(url: URL(string: "\(PropertiesService.shared.s3BaseURL)/\(video.thumbnail_key)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .center) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Button(action: {
                onVisibilityToggle(video.visibility == "public" ? "private" : "public")
            }) {
                Label(
                    video.visibility == "public" ? "Public" : "Private",
                    systemImage: video.visibility == "public" ? "eye" : "eye.slash"
                )
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(video.visibility == "public" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(4)
            }
        }
    }
}
