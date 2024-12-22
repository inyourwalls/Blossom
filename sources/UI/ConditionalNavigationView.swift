import SwiftUI

struct ConditionalNavigationView<Content: View>: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationView {
                    content
                }
            } else {
                content
            }
        }
    }
}
