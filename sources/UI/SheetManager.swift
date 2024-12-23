import SwiftUI

class SheetManager: ObservableObject {
    @Published var wallpaperSelector = false
    @Published var selectedWallpaper: WallpaperSelection? = nil
    
    func closeAll() {
        wallpaperSelector = false
        selectedWallpaper = nil
    }
}
