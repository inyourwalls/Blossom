import SwiftUI

struct BlossomView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var isLoopEnabled: Bool = false
    @State private var isInitialized: Bool = false
    @State private var interactionAllowed: Bool = false
    
    @State private var aboutAlert = false
    
    @ObservedObject var sheetManager: SheetManager = SheetManager()
    
    private var daemon: Daemon = Daemon()
    
    var body: some View {
        ConditionalNavigationView {
            VStack(spacing: 10) {
                Spacer()
                
                Image(uiImage: UIImage(named: "Icon")!)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                Spacer()
            
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
                    
                    if horizontalSizeClass != .compact {
                        Section {
                            Button(action: {
                                self.aboutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.purple)
                                        .frame(width: 30, height: 30)
                                    
                                    Text("About")
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollDisabled(true)
                .frame(height: horizontalSizeClass == .compact ? 190 : 260)
            }
            .navigationTitle("Blossom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        aboutAlert = true
                    }) {
                        Image(systemName: "info.circle") .font(.title3)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .onChange(of: isLoopEnabled) { newValue in
                if isInitialized {
                    daemon.toggle()
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
        .alert(isPresented: $aboutAlert) {
            Alert(
                title: Text("Blossom"),
                message: Text("iOS 17 offers the ability to set a live photo as your wallpaper, but it comes with limitations and doesn’t even work as expected.\n\nThis app allows you to swap live photo from camera roll with a custom 5 second video and make it loop if desired.\n\nIf you encounter any issues, refer to the FAQ section in the GitHub repository."),
                primaryButton: .default(Text("Close")),
                secondaryButton: .default(Text("Visit GitHub repository")) {
                    if let url = URL(string: "https://github.com/inyourwalls/Blossom") {
                        UIApplication.shared.open(url)
                    }
                }
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
