import SwiftUI

struct BlossomView: View {
    
    @State private var isLoopEnabled: Bool = false
    @State private var interactionAllowed: Bool = false
    
    @ObservedObject var sheetManager: SheetManager = SheetManager()
    
    private var daemon: Daemon = Daemon()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Image(uiImage: UIImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
                    .padding(.top, 100)
                    .padding(.bottom, 100)
            
                List {
                    Section(header:
                        HStack {
                            Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            Text("Blossom")
                            .foregroundColor(.purple)
                        }
                        .padding(.bottom, 5)
                    ) {
                        Button(action: {
                            sheetManager.wallpaperSelector = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.purple)
                                    .frame(width: 30, height: 30)
                                Text("Change Wallpaper")
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.purple)
                                .frame(width: 30, height: 30)
                            
                            Text("Loop")
                            
                            Spacer()
                            Toggle("", isOn: $isLoopEnabled)
                                .frame(width: 50, height: 0)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .disabled(!interactionAllowed)
                                .onTapGesture {
                                    if !interactionAllowed {
                                        return
                                    }
                                    
                                    daemon.toggle()
                                    
                                    if !isLoopEnabled {
                                        sheetManager.showAlert(title: "Note", message: "Live wallpapers will now loop.\nIf you want to set new wallpapers, disable this or you won't be able to set them.")
                                    }
                                }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollDisabled(true)
            }
            .navigationTitle("Blossom")
            .navigationBarTitleDisplayMode(.inline)
            
            .onAppear {
                daemon.callback = { allowInteraction in
                    interactionAllowed = allowInteraction
                }
                
                self.isLoopEnabled = IsHUDEnabled()
                self.interactionAllowed = true
            }
        }
        .alert(isPresented: $sheetManager.alertShown) {
            Alert(
                title: Text(sheetManager.alertTitle),
                message: Text(sheetManager.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $sheetManager.wallpaperSelector, content: {
            WallpaperSelectorModal(sheetManager: sheetManager)
        })
        .preferredColorScheme(.light)
    }
}

#Preview {
    BlossomView()
}
