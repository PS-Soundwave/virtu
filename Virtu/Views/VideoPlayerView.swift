import SwiftUI
import AVKit

// Custom video player view that handles HLS streams
struct VideoPlayerView: View {
    let video: Video

    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            // Video player
            if let player = player {
                AVPlayerControllerRepresentable(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onScrollVisibilityChange(threshold: 1) { visible in
                        isVisible = visible

                        if visible {
                            player.play()
                        } else {
                            player.pause()
                        }
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            if isVisible {
                                player.play()
                            }
                        } else {
                            player.pause()
                        }
                    }
            }

            if !isPlaying {
                AsyncImage(url: video.thumbnailURL) { image in
                    image
                        .resizable()
                } placeholder: {
                    Color.gray
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if player == nil {
                let player = AVPlayer(url: video.streamURL)
                self.player = player
                
                player.playImmediately(atRate: 1)
                
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        // Monitor playback status
                        group.addTask {
                            for await status in player.publisher(for: \.timeControlStatus).values {
                                await MainActor.run {
                                    isPlaying = isPlaying || status == .playing && player.currentItem?.isPlaybackLikelyToKeepUp == true
                                }
                            }
                        }
                        
                        // Monitor buffer state
                        group.addTask {
                            guard let item = player.currentItem else { return }
                            for await keepUp in item.publisher(for: \.isPlaybackLikelyToKeepUp).values {
                                await MainActor.run {
                                    isPlaying = isPlaying || keepUp && player.timeControlStatus == .playing
                                }
                            }
                        }
                    }
                }
            }
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
