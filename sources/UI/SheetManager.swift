import SwiftUI

class SheetManager: ObservableObject {
    @Published var wallpaperSelector = false
    @Published var selectedWallpaper: WallpaperSelection? = nil
    @Published var cropGuide = false
    
    func closeAll() {
        wallpaperSelector = false
        selectedWallpaper = nil
        cropGuide = false
    }
}
