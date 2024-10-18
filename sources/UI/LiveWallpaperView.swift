import SwiftUI
import AVKit

struct LiveWallpaperView: View {
    let wallpaperPath: String
    @State var player: AVPlayer?
    
    var body: some View {
        if player != nil {
            AVPlayerControllerRepresented(player: player!)
                .onAppear {
                    player!.isMuted = true
                    player!.play()
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                        if(player?.currentTime() == player?.currentItem?.duration) {
                            player!.seek(to: .zero)
                            player!.play()
                        }
                    }
                }
                .onDisappear {
                    player!.pause()
                }
                .scaledToFill()
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.0, anchor: .center)
                .onAppear {
                    if player == nil {
                        let fileURL = URL(fileURLWithPath: wallpaperPath)
                        self.player = AVPlayer(url: fileURL)
                    }
                }
        }
    }
}


struct AVPlayerControllerRepresented : UIViewControllerRepresentable {
    var player : AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
