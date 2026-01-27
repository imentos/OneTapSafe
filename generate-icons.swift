#!/usr/bin/swift

import SwiftUI
import AppKit

// MARK: - Icon Generator

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0x34/255.0, green: 0xC7/255.0, blue: 0x59/255.0),
                    Color(red: 0x30/255.0, green: 0xD1/255.0, blue: 0x58/255.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main composition
            ZStack {
                // Heart outline (white)
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.65, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                
                // Thumbs up inside (green to match background)
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(Color(red: 0x34/255.0, green: 0xC7/255.0, blue: 0x59/255.0))
                    .offset(y: -size * 0.02)
                    .shadow(color: .white.opacity(0.3), radius: size * 0.01)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Image Renderer Helper

@MainActor
func generateIcon(size: CGFloat, filename: String) {
    let view = AppIconView(size: size)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    
    if let cgImage = renderer.cgImage {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        
        if let tiffData = nsImage.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            
            let outputPath = "./OneTapSafe/Assets.xcassets/AppIcon.appiconset/\(filename)"
            let url = URL(fileURLWithPath: outputPath)
            
            do {
                try pngData.write(to: url)
                print("✅ Generated: \(filename) (\(Int(size))x\(Int(size))px)")
            } catch {
                print("❌ Failed to save \(filename): \(error)")
            }
        }
    }
}

// MARK: - Main

print("🎨 Generating OneTapOK App Icons...")
print("")

let sizes: [(size: CGFloat, filename: String)] = [
    (40, "Icon-20@2x.png"),
    (60, "Icon-20@3x.png"),
    (58, "Icon-29@2x.png"),
    (87, "Icon-29@3x.png"),
    (80, "Icon-40@2x.png"),
    (120, "Icon-40@3x.png"),
    (120, "Icon-60@2x.png"),
    (180, "Icon-60@3x.png"),
    (1024, "Icon-1024.png")
]

Task { @MainActor in
    for (size, filename) in sizes {
        generateIcon(size: size, filename: filename)
    }
    
    print("")
    print("✨ All icons generated successfully!")
    print("📁 Location: OneTapSafe/Assets.xcassets/AppIcon.appiconset/")
    print("")
    print("🎯 Next: Open OneTapSafe.xcodeproj and verify icons appear")
    
    exit(0)
}

RunLoop.main.run()
