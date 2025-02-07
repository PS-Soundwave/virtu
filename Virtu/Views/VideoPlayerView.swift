import SwiftUI
import AVKit

// Custom video player view that handles HLS streams
struct VideoPlayerView: View {
    let video: Video

    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player {
                AVPlayerControllerRepresentable(player: player).frame(maxWidth: .infinity, maxHeight: .infinity)
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
        }
        .onAppear {
            if (player == nil) {
                let player = AVPlayer(url: video.streamURL)

                self.player = player
            }

            player?.seek(to: .zero)
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
