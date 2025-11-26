import SwiftUI

extension Color {
    // Helper initializer to create Color from hex code
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex & 0xFF0000) >> 16) / 255
        let green = Double((hex & 0x00FF00) >> 8) / 255
        let blue = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    static let primaryBrand = Color(hex: 0xFFB000)
    static let secondaryBrand = Color(hex: 0xFF6A3D)
    static let accentBrand = Color(hex: 0xD84CBF)
    static let accentAlt = Color(hex: 0x3A3DAE)
    static let warningBrand = Color(hex: 0xE6503C)
    static let cardBackground = Color.black.opacity(0.08) // fallback for both modes
    static let surfaceBackground = Color.white.opacity(0.12)
}
