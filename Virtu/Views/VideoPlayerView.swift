import SwiftUI
import AVKit

// Custom video player view that handles HLS streams
struct VideoPlayerView: View {
    let video: Video
    var isFullScreen: Bool = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
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

            if false {
                AsyncImage(url: video.thumbnailURL) { image in
                    image
                        .resizable()
                } placeholder: {
                    Color.gray
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .topLeading) {
            if isFullScreen {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(.black.opacity(0.3), in: Circle())
                }
                .padding()
            }
        }
        .onAppear {
            if player == nil {
                let player = AVPlayer(url: video.streamURL)
                self.player = player
                
                if isFullScreen {
                    player.play()
                }
            }
        }
        .onDisappear {
            player?.pause()
            if isFullScreen {
                player = nil
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
