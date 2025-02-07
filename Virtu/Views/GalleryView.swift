import SwiftUI

// TODO: Review
struct GalleryView: View {
    let username: Binding<String>

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
                        Text(username.wrappedValue)
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
                .background(.gray.opacity(0.3))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ContentView()
}
