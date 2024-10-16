import UIKit
import SwiftUI

class BlossomViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blossomView = BlossomView()
        let hostingController = UIHostingController(rootView: blossomView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        overrideUserInterfaceStyle = .light
        UIApplication.shared.keyWindow?.tintColor = .purple
        
        hostingController.didMove(toParent: self)
    }
}
