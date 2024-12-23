import UIKit
import SwiftUI
import AVFoundation
import MobileCoreServices
import PryntTrimmerView

class VideoTrimmerViewController: UIViewController {

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!

    var asset: AVAsset?
    var onComplete: ((CMTime, CMTime) -> Void)?
    
    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.darkGray
        
        trimmerView.minDuration = 5.0
        
        if let asset = asset {
            loadAsset(asset)
        }
    }

    @IBAction func done(_ sender: Any) {
        let tolerance: Double = 0.05
        
        let diff = CMTimeGetSeconds(trimmerView.endTime!) - CMTimeGetSeconds(trimmerView.startTime!)
        if(abs(diff - 5) > tolerance) {
            let formattedDiff = String(format: "%.2f", diff)
            let alert = UIAlertController(title: "Error", message: "Trim the video to be exactly 5 seconds long.\nCurrent duration: \(formattedDiff)s", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
            return
        }
        
        onComplete?(trimmerView.startTime!, trimmerView.endTime!)
    }
    
    func loadAsset(_ asset: AVAsset) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.trimmerView.delegate = self
            self.trimmerView.asset = asset
            self.addVideoPlayer(with: asset, playerView: self.playerView)
        }
    }

    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoTrimmerViewController.itemDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        
        player!.play()
        startPlaybackTimeChecker()
    }

    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
            if (player?.isPlaying != true) {
                player?.play()
            }
        }
    }

    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector:
            #selector(VideoTrimmerViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }

    func stopPlaybackTimeChecker() {

        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }

    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)

        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

extension VideoTrimmerViewController: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}

struct VideoTrimmerViewControllerRepresentable: UIViewControllerRepresentable {
    var asset: AVAsset?
    var onComplete: ((CMTime, CMTime) -> Void)?
    
    func makeUIViewController(context: Context) -> VideoTrimmerViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "trimmerViewController") as? VideoTrimmerViewController else {
            fatalError("Could not find controller")
        }
        
        viewController.asset = asset
        viewController.onComplete = onComplete
        
        return viewController

    }
    
    func updateUIViewController(_ uiViewController: VideoTrimmerViewController, context: Context) {

    }
}
