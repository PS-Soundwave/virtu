import SwiftUI

// TODO: Review
struct GalleryView: View {
    let user: Binding<User?>
    @State private var videos: [Video] = []
    @State private var isLoading = false
    @State private var error: Error?

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
                            VideoThumbnail(video: video)
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            await loadVideos()
        }
        .onChange(of: user.wrappedValue?.id) { _, _ in
            Task {
                await loadVideos()
            }
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
        GeometryReader { geometry in
            AsyncImage(url: video.streamURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
            } placeholder: {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .background(.gray.opacity(0.3))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ContentView()
}
