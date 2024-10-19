import SwiftUI
import AVFoundation

struct CropGuideView: View {
    
    @State var sheetManager: SheetManager
    @State var showText = true
    
    var body: some View {
        ZStack {
            LiveWallpaperView(wallpaperPath: "setup", player: AVPlayer(url: createLocalUrl(for: "setup", ofType: "mov")! as URL))

            if showText {
                let width = Int( UIScreen.main.bounds.size.width * UIScreen.main.scale)
                let height = Int(UIScreen.main.bounds.size.height * UIScreen.main.scale)
                
                VStack {
                    Spacer()
                    Text("Your video must be exactly\n5 seconds long\nand cropped to your screen resolution of \(width) x \(height).")
                        .font(.headline)
                        .frame(width: 250)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                        .padding(.bottom, 200)
                }
            }
        }
        .preferredColorScheme(.dark)
        .background(.black)
        .onTapGesture {
            showText = false
        }
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
    CropGuideView(sheetManager: SheetManager())
}
