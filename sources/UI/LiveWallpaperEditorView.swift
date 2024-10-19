import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import UIKit
import System

struct LiveWallpaperEditorView: View {
    
    @ObservedObject var sheetManager: SheetManager
    
    @State var liveWallpaper: WallpaperSelection? = nil
    @State private var player = AVPlayer()
    @State private var videoURL: URL? = nil
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(2.0, anchor: .center)
        }
        .onAppear {
            if let liveWallpaper = liveWallpaper {
                loadVideo(liveWallpaper.userVideo)
            }
        }
        .padding()
        .preferredColorScheme(.light)
    }
    
    private func loadVideo(_ item: PhotosPickerItem) {
        Task {
            do {
                if let url = try await item.loadTransferable(type: VideoTransferable.self) {
                    let playerItem = AVPlayerItem(url: url.url)
                    player.replaceCurrentItem(with: playerItem)
                    
                    self.setWallpaper()
                }
            } catch {
                DispatchQueue.main.async {
                    sheetManager.showAlert(title: "Error", message: "Failed to load the video: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setWallpaper() {
        var videoAsset = player.currentItem!.asset
        
        // TODO: Create a video showing how to crop the wallpaper and open a guide view
        
        let durationSeconds = CMTimeGetSeconds(videoAsset.duration)
        let targetDuration: Double = 5.0
        let tolerance: Double = 0.09

        if abs(durationSeconds - targetDuration) > tolerance {
            sheetManager.closeAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sheetManager.showAlert(title: "Error", message: "Video must be exactly 5.0 seconds long.\nDuration of the selected video: \(durationSeconds)s")
            }
            return
        }

        let track = videoAsset.tracks(withMediaType: AVMediaType.video).first!
        let size = track.naturalSize.applying(track.preferredTransform)
        let videoSize = CGSize(width: fabs(size.width), height: fabs(size.height))

        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.size.height * UIScreen.main.scale
        
        let videoAspectRatio = videoSize.width / videoSize.height
        let screenAspectRatio = screenWidth / screenHeight

        if abs(videoAspectRatio - screenAspectRatio) > 0.01 {
            sheetManager.closeAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sheetManager.showAlert(title: "Error", message: "Video should have the same aspect ratio as your screen.")
            }
            return
        }
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = URL(filePath: liveWallpaper!.wallpaper.path)
        exportSession.outputFileType = .mov

        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 5, preferredTimescale: 600))
        exportSession.timeRange = timeRange
        
        let composition = AVMutableComposition()
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else { return }

        let videoComposition = AVMutableVideoComposition(asset: videoAsset) { request in
            let source = request.sourceImage.clampedToExtent()
            
            let targetSize = CGSize(width: screenWidth, height: screenHeight)
            let transform = CGAffineTransform(scaleX: targetSize.width / source.extent.width,
                                               y: targetSize.height / source.extent.height)
            
            let resizedImage = source.transformed(by: transform)
            request.finish(with: resizedImage, context: nil)
        }
        
        do {
            try FileManager.default.moveItem(atPath: liveWallpaper!.wallpaper.path, toPath: liveWallpaper!.wallpaper.path + ".backup." + UUID().uuidString)
        } catch {
            sheetManager.closeAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sheetManager.showAlert(title: "Error", message: "Failed to rename .MOV file: \(error.localizedDescription)")
            }
            
        }
            
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
                imageGenerator.requestedTimeToleranceAfter = .zero
                imageGenerator.requestedTimeToleranceBefore = .zero
                
                let lastFrameTime = CMTime(seconds: durationSeconds, preferredTimescale: 600)
                
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: lastFrameTime)]) { _, image, _, result, _ in
                    if result == .succeeded, let cgImage = image {
                        let uiImage = UIImage(cgImage: cgImage)
                        let targetSize = CGSize(width: screenWidth, height: screenHeight)
                                
                        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
                        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                
                        if let heicData = uiImage.heicData(compressionQuality: 1.0) {
                            do {
                                try FileManager.default.moveItem(atPath: liveWallpaper!.wallpaper.stillImagePath, toPath: liveWallpaper!.wallpaper.stillImagePath + ".backup." + UUID().uuidString)
                                                            
                                try heicData.write(to: URL(filePath: liveWallpaper!.wallpaper.stillImagePath))
                                
                                let adjusted = liveWallpaper!.wallpaper.wallpaperRootDirectory + "/input.segmentation/asset.resource/Adjusted.HEIC"
                                let proxy =  liveWallpaper!.wallpaper.wallpaperRootDirectory + "/input.segmentation/asset.resource/proxy.heic";
                                
                                if(FileManager.default.fileExists(atPath: adjusted)) {
                                    try FileManager.default.removeItem(atPath: adjusted);
                                }
                                
                                if(FileManager.default.fileExists(atPath: proxy)) {
                                    try FileManager.default.removeItem(atPath: proxy);
                                }
                                                            
                                if(!FileManager.default.fileExists(atPath: liveWallpaper!.wallpaper.contentsPath)) {
                                    DispatchQueue.main.async {
                                        sheetManager.closeAll()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            sheetManager.showAlert(title: "Error", message: "Contents.json file does not exist.")
                                        }
                                    }
                                    return
                                }
                                
                                do {
                                    let url = URL(filePath: liveWallpaper!.wallpaper.contentsPath)
                                    let data = try Data(contentsOf: url)
                                    let decoder = JSONDecoder()
                                    var contents = try decoder.decode(Contents.self, from: data)
                                    
                                    let deviceResolution = contents.properties.portraitLayout.deviceResolution
                                    
                                    contents.layers[0].frame.Width = deviceResolution.Width
                                    contents.layers[0].frame.Height = deviceResolution.Height
                                    contents.layers[0].frame.Y = 0
                                    contents.layers[0].frame.X = 0
                                    contents.layers[0].zPosition = 5
                                    contents.layers[0].identifier = "background"
                                    contents.layers[0].filename = "portrait-layer_background.HEIC"
                                    
                                    contents.layers[1].frame.Width = deviceResolution.Width
                                    contents.layers[1].frame.Height = deviceResolution.Height
                                    contents.layers[1].frame.Y = 0
                                    contents.layers[1].frame.X = 0
                                    contents.layers[1].zPosition = 6
                                    contents.layers[1].identifier = "settling-video"
                                    contents.layers[1].filename = "portrait-layer_settling-video.MOV"
                                    
                                    contents.properties.portraitLayout.visibleFrame.Width = deviceResolution.Width
                                    contents.properties.portraitLayout.visibleFrame.Height = deviceResolution.Height
                                    contents.properties.portraitLayout.visibleFrame.X = 0
                                    contents.properties.portraitLayout.visibleFrame.Y = 0
                                    
                                    contents.properties.portraitLayout.imageSize.Width = deviceResolution.Width
                                    contents.properties.portraitLayout.imageSize.Height = deviceResolution.Height
                                    
                                    contents.properties.portraitLayout.inactiveFrame.Width = deviceResolution.Width
                                    contents.properties.portraitLayout.inactiveFrame.Height = deviceResolution.Height
                                    contents.properties.portraitLayout.inactiveFrame.X = 0
                                    contents.properties.portraitLayout.inactiveFrame.Y = 0
                                    
                                    contents.properties.portraitLayout.parallaxPadding.Width = 0
                                    contents.properties.portraitLayout.parallaxPadding.Height = 0
                                    
                                    contents.properties.settlingEffectEnabled = true
                                    contents.properties.depthEnabled = false
                                    contents.properties.parallaxDisabled = false
                                    
                                    let encoder = JSONEncoder()
                                    encoder.outputFormatting = .prettyPrinted
                                    
                                    let encodedData = try encoder.encode(contents)
                                    try encodedData.write(to: url)
                                    
                                    //
                                    
                                    let wallpaper = Wallpaper()
                                    wallpaper.deleteSnapshots(liveWallpaper!.wallpaper.wallpaperVersionDirectory)
                                    wallpaper.restartPoster()
                                 
                                    DispatchQueue.main.async {
                                        sheetManager.closeAll()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            sheetManager.showAlert(title: "Success", message: "Live wallpaper is successfully changed.\n\nIf the last frame is different than from the video, try changing the wallpaper to another one and then change back.")
                                        }
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                        sheetManager.closeAll()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            sheetManager.showAlert(title: "Error", message: "Failed to patch Contents.json: \(error)")
                                        }
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    sheetManager.closeAll()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        sheetManager.showAlert(title: "Error", message: "Failed to export HEIC image: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    }
                }
            default:
                DispatchQueue.main.async {
                    sheetManager.closeAll()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        sheetManager.showAlert(title: "Error", message: "Failed to export video: \(exportSession.error.debugDescription)")
                    }
                }
            }
        }
    }
    
    private func loadVideoURL(_ item: PhotosPickerItem) async throws -> URL? {
        guard let video = try await item.loadTransferable(type: VideoTransferable.self) else {
          return nil
        }
        return video.url
    }
}

struct VideoTransferable: Transferable {
  let url: URL
  
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .movie) { exporting in
      return SentTransferredFile(exporting.url)
    } importing: { received in
      let origin = received.file
      let filename = origin.lastPathComponent
      let copied = URL.documentsDirectory.appendingPathComponent(filename)
      let filePath = copied.path()
      
      if FileManager.default.fileExists(atPath: filePath) {
        try FileManager.default.removeItem(atPath: filePath)
      }
      
      try FileManager.default.copyItem(at: origin, to: copied)
      return VideoTransferable(url: copied)
    }
  }
}

extension UIImage {
    func heicData(compressionQuality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
}

#Preview {
    LiveWallpaperEditorView(sheetManager: SheetManager())
}
