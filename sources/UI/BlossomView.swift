import SwiftUI

struct BlossomView: View {
    
    @State private var isLoopEnabled: Bool = false
    @State private var isInitialized: Bool = false
    @State private var interactionAllowed: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @ObservedObject var sheetManager: SheetManager = SheetManager()
    
    private var daemon: Daemon = Daemon()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Image(uiImage: UIImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
                    .padding(.top, 120)
                    .padding(.bottom, 120)
            
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
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollDisabled(true)
            }
            .navigationTitle("Blossom")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: isLoopEnabled) {
                if isInitialized {
                    daemon.toggle()
                    
                    if isLoopEnabled {
                        showAlert = true
                        alertMessage = "While this option is active, you are not able to create new wallpapers in iOS.\nDisable this to make a new wallpaper."
                    }
                }
            }
            .onAppear {
                daemon.callback = { allowInteraction in
                    interactionAllowed = allowInteraction
                }
                
                self.isLoopEnabled = daemon.isEnabled()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isInitialized = true
                    self.interactionAllowed = true
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Blossom"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $sheetManager.wallpaperSelector, content: {
            WallpaperSelectorModal(sheetManager: sheetManager)
        })
        .onChange(of: sheetManager.cropGuide) {
            if !sheetManager.cropGuide {
                sheetManager.closeAll()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    BlossomView()
}
