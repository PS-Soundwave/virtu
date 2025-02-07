import SwiftUI
import AVKit

// Custom video player view that handles HLS streams
struct VideoPlayerView: View {
    let video: Video

    var body: some View {
        let player = AVPlayer(url: video.streamURL)
        AVPlayerControllerRepresentable(player: player)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onScrollVisibilityChange(threshold: 1) { visible in
                if (visible) {
                    player.play()
                } else {
                    player.pause()
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
