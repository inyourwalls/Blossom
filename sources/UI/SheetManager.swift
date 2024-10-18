import SwiftUI

class SheetManager: ObservableObject {
    @Published var wallpaperSelector = false
    @Published var selectedWallpaper: WallpaperSelection? = nil
    
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var alertShown: Bool = false
    
    func showAlert(title: String, message: String) {
        alertShown = true
        alertTitle = title
        alertMessage = message
    }
    
    func closeAll() {
        wallpaperSelector = false
        selectedWallpaper = nil
    }
}
