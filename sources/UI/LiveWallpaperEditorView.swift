import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import UIKit
import AppleArchive
import System

struct LiveWallpaperEditorView: View {
    
    @ObservedObject var sheetManager: SheetManager
    
    @State var liveWallpaper: WallpaperSelection? = nil
    @State private var player = AVPlayer()
    @State private var videoLoadedSuccessfully = false
    
    var body: some View {
        VStack {
            if !videoLoadedSuccessfully {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(2.0, anchor: .center)
            } else {
                Text(liveWallpaper!.wallpaper.wallpaperRootDirectory)
                
                Button(action: {
                    setWallpaper()
                }) {
                    Text("Test Set")
                }
                
                LiveWallpaperView(wallpaperPath: "", player: player)
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear {
            if let liveWallpaper = liveWallpaper {
                loadVideo(liveWallpaper.userVideo)
            }
        }
        .alert(isPresented: $sheetManager.alertShown) {
            Alert(
                title: Text(sheetManager.alertTitle),
                message: Text(sheetManager.alertMessage),
                dismissButton: .default(Text("OK"))
            )
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
                    self.videoLoadedSuccessfully = true
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
        
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = URL(filePath: liveWallpaper!.wallpaper.path)
        exportSession.outputFileType = .mov
        
        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 5, preferredTimescale: 600))
        exportSession.timeRange = timeRange
        
        do {
            try FileManager.default.moveItem(atPath: liveWallpaper!.wallpaper.path, toPath: liveWallpaper!.wallpaper.path + ".backup." + UUID().uuidString)
        } catch {
            sheetManager.showAlert(title: "Error", message: "Failed to rename .MOV file: \(error.localizedDescription)")
        }
            
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
                imageGenerator.requestedTimeToleranceAfter = .zero
                imageGenerator.requestedTimeToleranceBefore = .zero
                
                let duration = videoAsset.duration
                let lastFrameTime = CMTime(seconds: 5.0/* - 0.01*/, preferredTimescale: 600)
                
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: lastFrameTime)]) { _, image, _, result, _ in
                    if result == .succeeded, let cgImage = image {
                        let uiImage = UIImage(cgImage: cgImage)
                        
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
                                        sheetManager.showAlert(title: "Error", message: "Contents.json file does not exist.")
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
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            sheetManager.showAlert(title: "Success", message: "Live wallpaper is successfully changed.\nNote that if you wish to edit lockscreen widgets or other wallpaper settings, the video will be reset.")
                                        }
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                        sheetManager.showAlert(title: "Error", message: "Failed to patch Contents.json: \(error)")
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    sheetManager.showAlert(title: "Error", message: "Failed to export HEIC image: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            default:
                sheetManager.showAlert(title: "Error", message: "Failed to export video: \(exportSession.error.debugDescription)")
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
