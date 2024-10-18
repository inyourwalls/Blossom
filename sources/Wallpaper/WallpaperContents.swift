struct Contents: Codable {
    var version: Int
    var layers: [Layer]
    var properties: Properties
}

struct Layer: Codable {
    var frame: Frame
    var filename: String
    var zPosition: Int
    var identifier: String
}

struct Frame: Codable {
    var Width: Double
    var Height: Double
    var X: Double
    var Y: Double
}

struct Resolution: Codable {
    var Width: Double
    var Height: Double
}

struct Properties: Codable {
    var portraitLayout: Layout
    
    var settlingEffectEnabled: Bool
    var depthEnabled: Bool
    var clockAreaLuminance: Double
    var parallaxDisabled: Bool
}

struct Layout: Codable {
    var clockIntersection: Int
    var deviceResolution: Resolution
    var visibleFrame: Frame
    var timeFrame: Frame
    var clockLayerOrder: String
    var inactiveFrame: Frame
    var imageSize: Resolution
    var parallaxPadding: Resolution
}
