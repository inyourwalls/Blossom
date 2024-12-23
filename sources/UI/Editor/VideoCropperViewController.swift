import UIKit
import SwiftUI
import Photos
import PryntTrimmerView
import AVFoundation

class VideoCropperViewController: UIViewController {

    @IBOutlet weak var videoCropView: VideoCropView!
    @IBOutlet weak var selectThumbView: ThumbSelectorView!
    
    var asset: AVAsset?
    var trimStartTime: CMTime = CMTime()
    var trimEndTime: CMTime = CMTime()
    var onComplete: ((AVAsset, UIImage) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            videoCropView.setAspectRatio(CGSize(width: 3, height: 4), animated: false)
        } else {
            videoCropView.setAspectRatio(CGSize(width: 9, height: 19.5), animated: false)
        }
        
        if let asset = asset {
            self.loadAsset(asset)
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
    
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    func loadAsset(_ asset: AVAsset) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.selectThumbView.asset = asset
            self.selectThumbView.delegate = self
            self.videoCropView.asset = asset
        }
    }
    
    @IBAction func done(_ sender: Any) {
        onLoading?(true)
        try? prepareAssetComposition()
    }

    func prepareAssetComposition() throws {
        guard let asset = videoCropView.asset, let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            onLoading?(false)
            return
        }

        let assetComposition = AVMutableComposition()
        let trackTimeRange = CMTimeRangeMake(start: trimStartTime, duration: trimEndTime)

        guard let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            onLoading?(false)
            return
        }

        try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)

        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)

        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)

        var renderSize = CGSize(width: 16 * videoCropView.aspectRatio.width * 18,
                                height: 16 * videoCropView.aspectRatio.height * 18)
        
        let transform = getTransform(for: videoTrack)

        layerInstructions.setTransform(transform, at: CMTime.zero)
        layerInstructions.setOpacity(1.0, at: CMTime.zero)
        mainInstructions.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.instructions = [mainInstructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mov")
        try? FileManager.default.removeItem(at: url)

        let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = url
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                if let url = exportSession?.outputURL, exportSession?.status == .completed {
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.requestedTimeToleranceBefore = CMTime.zero
                    generator.requestedTimeToleranceAfter = CMTime.zero
                    generator.appliesPreferredTrackTransform = true
                    let image = try? generator.copyCGImage(at: self.trimEndTime, actualTime: nil)
                    if let image = image {
                        let selectedImage = UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
                        let croppedImage = selectedImage.crop(in: self.videoCropView.getImageCropFrame())!
                        
                        let scaledImage = croppedImage.scalePreservingAspectRatio(targetSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))

                        self.onLoading?(false)
                        self.onComplete?(AVAsset(url: url), scaledImage)
                    } else {
                        self.onLoading?(false)
                        self.showError(message: "Failed to extract last frame of the video")
                    }
                } else {
                    self.onLoading?(false)
                    let error = exportSession?.error
                    self.showError(message: "Error exporting video: \(String(describing: error))")
                }
            }
        })
    }

    private func getTransform(for videoTrack: AVAssetTrack) -> CGAffineTransform {
        let renderSize = CGSize(width: 16 * videoCropView.aspectRatio.width * 18,
                                height: 16 * videoCropView.aspectRatio.height * 18)
        let cropFrame = videoCropView.getImageCropFrame()
        let renderScale = renderSize.width / cropFrame.width
        let offset = CGPoint(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
        let rotation = atan2(videoTrack.preferredTransform.b, videoTrack.preferredTransform.a)

        var rotationOffset = CGPoint(x: 0, y: 0)

        if videoTrack.preferredTransform.b == -1.0 {
            rotationOffset.y = videoTrack.naturalSize.width
        } else if videoTrack.preferredTransform.c == -1.0 {
            rotationOffset.x = videoTrack.naturalSize.height
        } else if videoTrack.preferredTransform.a == -1.0 {
            rotationOffset.x = videoTrack.naturalSize.width
            rotationOffset.y = videoTrack.naturalSize.height
        }

        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: renderScale, y: renderScale)
        transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
        transform = transform.rotated(by: rotation)

        print("track size \(videoTrack.naturalSize)")
        print("preferred Transform = \(videoTrack.preferredTransform)")
        print("rotation angle \(rotation)")
        print("rotation offset \(rotationOffset)")
        print("actual Transform = \(transform)")
        return transform
    }
}

extension VideoCropperViewController: ThumbSelectorViewDelegate {
    func didChangeThumbPosition(_ imageTime: CMTime) {
        videoCropView.player?.seek(to: imageTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

extension UIImage {
    func crop(in frame: CGRect) -> UIImage? {
        if let croppedImage = self.cgImage?.cropping(to: frame) {
            return UIImage(cgImage: croppedImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
    
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
           
        let scaleFactor = min(widthRatio, heightRatio)
           
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
           
        return scaledImage
    }
}

struct VideoCropperViewControllerRepresentable: UIViewControllerRepresentable {
    var asset: AVAsset?
    var trimStartTime: CMTime
    var trimEndTime: CMTime
    var onComplete: ((AVAsset, UIImage) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    func makeUIViewController(context: Context) -> VideoCropperViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "videoCropViewController") as? VideoCropperViewController else {
            fatalError("Could not find controller")
        }
        
        viewController.onComplete = onComplete
        viewController.onLoading = onLoading
        viewController.trimStartTime = trimStartTime
        viewController.trimEndTime = trimEndTime
        viewController.asset = asset
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: VideoCropperViewController, context: Context) {
        
    }
}
