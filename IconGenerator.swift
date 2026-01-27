import SwiftUI

/// OneTapOK App Icon Generator
/// Uses SF Symbols: hand.thumbsup.fill inside heart.fill
/// Generates all required icon sizes for App Store submission

struct AppIconGenerator: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient (green - safety theme)
            LinearGradient(
                colors: [Color(hex: "34C759"), Color(hex: "30D158")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon composition
            ZStack {
                // Heart outline (larger, behind)
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.65, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                
                // Thumbs up (centered inside heart)
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(Color(hex: "34C759"))
                    .offset(y: -size * 0.02)
                    .shadow(color: .white.opacity(0.3), radius: size * 0.01)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Icon Size Generator

struct IconSizeSet {
    static let sizes: [(name: String, size: CGFloat, scale: Int)] = [
        // iPhone Notification
        ("20pt", 20, 2), ("20pt", 20, 3),
        // iPhone Settings
        ("29pt", 29, 2), ("29pt", 29, 3),
        // iPhone Spotlight
        ("40pt", 40, 2), ("40pt", 40, 3),
        // iPhone App
        ("60pt", 60, 2), ("60pt", 60, 3),
        // iPad Notifications
        ("20pt-ipad", 20, 1), ("20pt-ipad", 20, 2),
        // iPad Settings
        ("29pt-ipad", 29, 1), ("29pt-ipad", 29, 2),
        // iPad Spotlight
        ("40pt-ipad", 40, 1), ("40pt-ipad", 40, 2),
        // iPad App
        ("76pt", 76, 1), ("76pt", 76, 2),
        // iPad Pro
        ("83.5pt", 83.5, 2),
        // App Store
        ("1024pt", 1024, 1)
    ]
    
    static func generateAll() {
        for (name, size, scale) in sizes {
            let pixelSize = size * CGFloat(scale)
            let icon = AppIconGenerator(size: pixelSize)
            
            // Render to image
            let renderer = ImageRenderer(content: icon)
            renderer.scale = 1.0 // Already scaled
            
            if let image = renderer.cgImage {
                let filename = "\(name)@\(scale)x.png"
                // Save to Assets.xcassets/AppIcon.appiconset/
                print("Generated: \(filename) (\(Int(pixelSize))x\(Int(pixelSize))px)")
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("App Icon - 1024x1024") {
    AppIconGenerator(size: 1024)
}

#Preview("App Icon - 180x180") {
    AppIconGenerator(size: 180)
}

#Preview("App Icon - 60x60") {
    AppIconGenerator(size: 60)
}

// MARK: - Alternative Design Options

struct AppIconAlternativeA: View {
    // lock.iphone with hand.tap instead of thumbsup
    let size: CGFloat
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "007AFF"), Color(hex: "34C759")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ZStack {
                Image(systemName: "lock.iphone")
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(x: size * 0.1, y: size * 0.12)
            }
        }
        .frame(width: size, height: size)
    }
}

struct AppIconAlternativeB: View {
    // lock.iphone with checkmark.circle overlay
    let size: CGFloat
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "34C759"), Color(hex: "30D158")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ZStack {
                Image(systemName: "lock.iphone")
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                // Checkmark badge (top-right)
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.32, height: size * 0.32)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.18, weight: .bold))
                        .foregroundStyle(Color(hex: "34C759"))
                }
                .offset(x: size * 0.18, y: -size * 0.18)
                .shadow(color: .black.opacity(0.15), radius: size * 0.02)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("Alternative A - hand.tap") {
    AppIconAlternativeA(size: 1024)
}

#Preview("Alternative B - checkmark badge") {
    AppIconAlternativeB(size: 1024)
}
