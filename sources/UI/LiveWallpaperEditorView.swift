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
    
    @State private var activeAlert: SheetAlert?
    
    @State private var ignoreFileSizeCheck: Bool = false
    
    struct SheetAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let primaryAction: (() -> Void)?
        let secondaryAction: (() -> Void)?
        let primaryText: String?
        let secondaryText: String?
    }
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(2.0, anchor: .center)
                .padding(25)
        }
        .onAppear {
            if let liveWallpaper = liveWallpaper {
                loadVideo(liveWallpaper.userVideo)
            }
        }
        .alert(item: $activeAlert) { alert in
            if let primaryAction = alert.primaryAction, let secondaryAction = alert.secondaryAction {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text(alert.primaryText ?? "")) {
                        primaryAction()
                    },
                    secondaryButton: .default(Text(alert.secondaryText ?? "")) {
                        secondaryAction()
                    }
                )
            } else {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $sheetManager.cropGuide, content: {
            CropGuideView(sheetManager: sheetManager)
        })
        .padding()
        .preferredColorScheme(.light)
        .background(.white)
        .cornerRadius(.infinity)
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
                print("Video loading error: \(error)")
            }
        }
    }
    
    private func setWallpaper() {
        let videoAsset = player.currentItem!.asset
        
        let durationSeconds = CMTimeGetSeconds(videoAsset.duration)
        let targetDuration: Double = 5.0
        let tolerance: Double = 0.09

        let track = videoAsset.tracks(withMediaType: AVMediaType.video).first!
        let size = track.naturalSize.applying(track.preferredTransform)

        let videoSize = CGSize(width: fabs(size.width), height: fabs(size.height))
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.size.height * UIScreen.main.scale
        
        let videoAspectRatio = videoSize.width / videoSize.height
        let screenAspectRatio = screenWidth / screenHeight
        
        if abs(durationSeconds - targetDuration) > tolerance {
            sheetManager.cropGuide = true
            return
        }
        
        let fileSize = self.assetFileSize(player: player)
        if !ignoreFileSizeCheck && fileSize >= 7 {
            let formattedFileSize = String(format: "%.2f", fileSize)
            activeAlert = SheetAlert(
                title: "Warning",
                message: "The selected video file size is \(formattedFileSize)MB. The recommended file size is below 7MB. If the wallpaper appears blank, you should compress the file. Continue anyway?",
                primaryAction: { self.ignoreFileSizeCheck = true; self.setWallpaper() },
                secondaryAction: { sheetManager.closeAll() },
                primaryText: "Continue anyway",
                secondaryText: "Cancel"
            )
            return
        }
        
        if abs(videoAspectRatio - screenAspectRatio) > 0.01 {
            activeAlert = SheetAlert(
                title: "Warning",
                message: "The selected video file must have \(screenWidth)x\(screenHeight) resolution.\nYou can continue anyway, but the end result might look wrong.\nYou can also check the video guide about fixing this issue using default Photos app.",
                primaryAction: { self.patch(resizeHEIC: false) },
                secondaryAction: { sheetManager.cropGuide = true },
                primaryText: "Continue anyway",
                secondaryText: "View guide"
            )
            return
        }
        
        self.patch(resizeHEIC: true)
    }
    
    private func assetFileSize(player: AVPlayer) -> Double {
        guard let currentItem = player.currentItem,
              let urlAsset = currentItem.asset as? AVURLAsset else {
            print("Unable to get URL from asset.")
            return 0
        }
        
        let fileURL = urlAsset.url
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            if let fileSize = fileAttributes[.size] as? UInt64 {
                let fileSizeInMB = Double(fileSize) / (1024 * 1024)
                return fileSizeInMB
            }
        } catch {
            print("Error retrieving file attributes: \(error)")
        }
        
        return 0
    }
    
    private func patch(resizeHEIC: Bool) {
        let videoAsset = player.currentItem!.asset
        
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.size.height * UIScreen.main.scale
    
        let durationSeconds = CMTimeGetSeconds(videoAsset.duration)
    
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = URL(filePath: liveWallpaper!.wallpaper.path)
        exportSession.outputFileType = .mov

        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 5, preferredTimescale: 600))
        exportSession.timeRange = timeRange
        
        let composition = AVMutableComposition()
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else { return }

        if resizeHEIC {
            let videoComposition = AVMutableVideoComposition(asset: videoAsset) { request in
                let source = request.sourceImage.clampedToExtent()
                
                let targetSize = CGSize(width: screenWidth, height: screenHeight)
                let transform = CGAffineTransform(scaleX: targetSize.width / source.extent.width, y: targetSize.height / source.extent.height)
                
                let resizedImage = source.transformed(by: transform)
                request.finish(with: resizedImage, context: nil)
            }
        }
        
        do {
            try FileManager.default.moveItem(atPath: liveWallpaper!.wallpaper.path, toPath: liveWallpaper!.wallpaper.path + ".backup." + UUID().uuidString)
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                activeAlert = SheetAlert(
                    title: "Error",
                    message: "Failed to rename .MOV file: \(error.localizedDescription)",
                    primaryAction: nil,
                    secondaryAction: nil,
                    primaryText: nil,
                    secondaryText: nil
                )
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
                                
                        if resizeHEIC {
                            UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
                            uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                        }
                
                        if let heicData = uiImage.heicData(compressionQuality: 1.0) {
                            do {
                                try FileManager.default.moveItem(atPath: liveWallpaper!.wallpaper.stillImagePath, toPath: liveWallpaper!.wallpaper.stillImagePath + ".backup." + UUID().uuidString)
                                                            
                                try heicData.write(to: URL(filePath: liveWallpaper!.wallpaper.stillImagePath))
                                
                                let adjusted = liveWallpaper!.wallpaper.wallpaperRootDirectory + "/input.segmentation/asset.resource/Adjusted.HEIC"
                                let proxy = liveWallpaper!.wallpaper.wallpaperRootDirectory + "/input.segmentation/asset.resource/proxy.heic";
                                
                                if(FileManager.default.fileExists(atPath: adjusted)) {
                                    try FileManager.default.removeItem(atPath: adjusted);
                                }
                                
                                if(FileManager.default.fileExists(atPath: proxy)) {
                                    try FileManager.default.removeItem(atPath: proxy);
                                }
                                                            
                                if(!FileManager.default.fileExists(atPath: liveWallpaper!.wallpaper.contentsPath)) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        activeAlert = SheetAlert(
                                            title: "Error",
                                            message: "Contents.json file does not exist.",
                                            primaryAction: nil,
                                            secondaryAction: nil,
                                            primaryText: nil,
                                            secondaryText: nil
                                        )
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

                                    sheetManager.closeAll()
                                    wallpaper.restartPosterBoard()
                                    wallpaper.respring()
                                } catch {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        activeAlert = SheetAlert(
                                            title: "Error",
                                            message: "Failed to patch Contents.json: \(error)",
                                            primaryAction: nil,
                                            secondaryAction: nil,
                                            primaryText: nil,
                                            secondaryText: nil
                                        )
                                    }
                                }
                            } catch {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    activeAlert = SheetAlert(
                                        title: "Error",
                                        message: "Failed to export HEIC image: \(error.localizedDescription)",
                                        primaryAction: nil,
                                        secondaryAction: nil,
                                        primaryText: nil,
                                        secondaryText: nil
                                    )
                                }
                            }
                        }
                    }
                }
                break
            default:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    activeAlert = SheetAlert(
                        title: "Error",
                        message: "Failed to export video: \(exportSession.error.debugDescription)",
                        primaryAction: nil,
                        secondaryAction: nil,
                        primaryText: nil,
                        secondaryText: nil
                    )
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
