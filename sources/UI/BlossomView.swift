import SwiftUI

struct BlossomView: View {
    
    @State private var isLoopEnabled: Bool = false
    @State private var delayInSeconds: Double = 5.0
    
    @State private var interactionAllowed: Bool = false
    
    private var daemon: Daemon = Daemon()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Image(uiImage: UIImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(10)
                    .padding(.top, 125)
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
                        HStack {
                            Image(systemName: "photo.circle")
                                .foregroundColor(.purple)
                                .frame(width: 30, height: 30)
                            Text("Set Wallpaper")
                        }
                        
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
                                }
                        }
                        
                        HStack {
                            Image(systemName: "timelapse")
                                .foregroundColor(.purple)
                                .frame(width: 30, height: 30)
                            
                            Text("Delay")
                            
                            Slider(value: $delayInSeconds, in: 1...60, step: /*0.5*/0.1)
                                .accentColor(.purple)
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                                .disabled(isLoopEnabled || !interactionAllowed)
                            
                            Text(String(format: "%.1fs", delayInSeconds))
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollDisabled(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationTitle("Blossom")
            .navigationBarTitleDisplayMode(.inline)
            
            .onAppear {
                let delay = UserDefaults.standard.double(forKey: "DelayInSeconds")
                self.delayInSeconds = delay == 0 ? 5 : delay
                
                daemon.callback = { allowInteraction in
                    interactionAllowed = allowInteraction
                }
                
                self.isLoopEnabled = IsHUDEnabled()
                self.interactionAllowed = true
            }
            .onChange(of: delayInSeconds) {
                daemon.setDelay(delayInSeconds)
                UserDefaults.standard.set(delayInSeconds, forKey: "DelayInSeconds")
            }
        }
    }
}
