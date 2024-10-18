import SwiftUI
import PhotosUI

struct WallpaperSelection: Identifiable {
    var wallpaper: LiveWallpaper
    var userVideo: PhotosPickerItem
    
    var id: String {
        return wallpaper.path
    }
}
