import SwiftUI
import AVFoundation

struct CropGuideView: View {
    var body: some View {
        ZStack {
            LiveWallpaperView(wallpaperPath: "setup", player: AVPlayer(url: createLocalUrl(for: "setup", ofType: "mov")! as URL))
        }
        .preferredColorScheme(.dark)
        .background(.black)
    }
    
    func createLocalUrl(for filename: String, ofType: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(filename).\(ofType)")
        
        guard fileManager.fileExists(atPath: url.path) else {
            guard let video = NSDataAsset(name: filename) else { return nil }
            fileManager.createFile(atPath: url.path, contents: video.data, attributes: nil)
            return url
        }
        
        return url
    }
}

#Preview {
    CropGuideView()
}
