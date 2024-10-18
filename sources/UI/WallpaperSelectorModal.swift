import SwiftUI
import PhotosUI
import AVFoundation

struct WallpaperSelectorModal: View {
    
    @ObservedObject var sheetManager: SheetManager
    
    @State private var wallpapers: [LiveWallpaper] = []
    @State private var isLoading = true
    
    @State private var selectedLiveWallpaper: LiveWallpaper? = nil
    @State private var selectedUserVideo: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(2.0, anchor: .center)
            } else {
                if wallpapers.isEmpty {
                    Image(systemName: "livephoto.slash")
                        .foregroundColor(.purple)
                        .scaleEffect(4.0, anchor: .center)
                        .padding(.bottom, 40)
          
                    Text("No Wallpapers Found")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .padding(.bottom, 5)
                    
                    Text("Open your lockscreen and create a new Live Photo wallpaper.")
                         .padding(.horizontal)
                         .multilineTextAlignment(.center)
                         .padding(.bottom, 10)
                    
                    Button(action: {
                        loadWallpapers()
                    }) {
                        Text("Refresh")
                            .foregroundStyle(.purple)
                    }
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            let columns = [
                                GridItem(.flexible(minimum: 0, maximum: geometry.size.width / 2), spacing: 20),
                                GridItem(.flexible(minimum: 0, maximum: geometry.size.width / 2), spacing: 20)
                            ]
                            
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(wallpapers, id: \.path) { wallpaper in
                                    if let path = wallpaper.path {
                                        PhotosPicker(selection: $selectedUserVideo, matching: .videos) {
                                            LiveWallpaperView(wallpaperPath: path)
                                                .frame(width: geometry.size.width / 2 - 20, height: geometry.size.width)
                                                .cornerRadius(10)
                                                .clipped()
                                                .containerShape(Rectangle())
                                        }
                                        .simultaneousGesture(TapGesture()
                                           .onEnded({
                                               self.selectedLiveWallpaper = wallpaper
                                           })
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(item: $sheetManager.selectedWallpaper) { item in
            LiveWallpaperEditorView(sheetManager: sheetManager, liveWallpaper: item)
                .onDisappear {
                    self.selectedUserVideo = nil
                }
        }
        .onChange(of: selectedUserVideo) {
            if let selectedUserVideo = selectedUserVideo {
                sheetManager.selectedWallpaper = WallpaperSelection(wallpaper: selectedLiveWallpaper!, userVideo: selectedUserVideo)
            }
        }
        .onAppear {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true)
            } catch {
                print("Failed to set audio session category")
            }
            
            loadWallpapers()
        }
    }
    
    private func loadWallpapers() {
        self.isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let wallpaperManager = Wallpaper()
            let loadedWallpapers = wallpaperManager.getLiveWallpapers()!
            
            DispatchQueue.main.async {
                self.wallpapers = loadedWallpapers
                self.isLoading = false
            }
        }
    }
}

#Preview {
    WallpaperSelectorModal(sheetManager: SheetManager())
}
