import SwiftUI

// TODO: Review
struct GalleryView: View {
    let user: Binding<User?>
    @State private var videos: [Video] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedVideo: Video?
    @State private var followInfo: FollowInfo?
    @State private var isLoadingFollow = false
    @State private var currentUser: User?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.wrappedValue?.username ?? "")
                                .font(.title2)
                                .bold()
                                .lineLimit(1)
                            
                            if let galleryUserId = user.wrappedValue?.id,
                               let currentUserId = currentUser?.id,
                               galleryUserId != currentUserId {
                                Button(action: {
                                    Task {
                                        await toggleFollow()
                                    }
                                }) {
                                    Text(followInfo?.isFollowing ?? false ? "Unfollow" : "Follow")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 120)
                                        .padding(.vertical, 8)
                                        .background(followInfo?.isFollowing ?? false ? Color.gray : Color.blue)
                                        .cornerRadius(20)
                                }
                                .disabled(isLoadingFollow)
                                .opacity(isLoadingFollow ? 0.5 : 1)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(followInfo?.followers ?? 0)")
                                .font(.headline)
                            Text("Followers")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(followInfo?.following ?? 0)")
                                .font(.headline)
                            Text("Following")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                }

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
            await loadFollowInfo()
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
    
    private func loadFollowInfo() async {
        guard let userId = user.wrappedValue?.id else { return }
        
        do {
            // First get the current user
            currentUser = try await UserService.shared.getCurrentUser()
            
            // Then get follow info
            let newFollowInfo = try await UserService.shared.getFollowInfo(userId: userId)
            
            await MainActor.run {
                followInfo = newFollowInfo
            }
        } catch {
            print("Error loading follow info: \(error)")
        }
    }
    
    private func toggleFollow() async {
        guard let userId = user.wrappedValue?.id else { return }
        guard !isLoadingFollow else { return }
        
        isLoadingFollow = true
        defer { isLoadingFollow = false }
        
        do {
            if followInfo?.isFollowing == true {
                try await UserService.shared.unfollowUser(userId: userId)
            } else {
                try await UserService.shared.followUser(userId: userId)
            }
            await loadFollowInfo()
        } catch {
            print("Failed to toggle follow: \(error)")
        }
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
