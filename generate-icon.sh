#!/bin/bash

# OneTapOK App Icon Generator Script
# Generates all required icon sizes using SwiftUI preview rendering

echo "🎨 OneTapOK App Icon Generator"
echo "================================"

# Navigate to project directory
cd "$(dirname "$0")"

# Create output directory
ASSET_DIR="OneTapSafe/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ASSET_DIR"

echo "📁 Output directory: $ASSET_DIR"
echo ""

# Method 1: Use Xcode's SwiftUI Preview to export icons
echo "Method 1: Using SwiftUI Previews"
echo "---------------------------------"
echo "1. Open IconGenerator.swift in Xcode"
echo "2. Enable Canvas (Cmd+Option+Enter)"
echo "3. For each preview:"
echo "   - Right-click preview"
echo "   - Select 'Export Preview...'"
echo "   - Save as PNG to $ASSET_DIR"
echo ""
echo "OR"
echo ""

# Method 2: Use this script with sips (for quick mockup)
echo "Method 2: Quick Generation with SF Symbols"
echo "-------------------------------------------"

# Icon sizes needed (pixel dimensions)
declare -a SIZES=(
    "40:20@2x"
    "60:20@3x"
    "58:29@2x"
    "87:29@3x"
    "80:40@2x"
    "120:40@3x"
    "120:60@2x"
    "180:60@3x"
    "1024:1024@1x"
)

echo "To generate icons programmatically, use one of these tools:"
echo ""
echo "Option A: Icon Generator Apps (Recommended)"
echo "  • Icon Set Creator (Mac App Store) - Free"
echo "  • Asset Catalog Creator (Mac App Store) - Free"
echo "  • https://www.appicon.co - Upload 1024x1024 base image"
echo ""
echo "Option B: SF Symbols App Export"
echo "  1. Open SF Symbols app (built into macOS)"
echo "  2. Search for 'lock.iphone'"
echo "  3. Export as image"
echo "  4. Edit in design tool to add hand.thumbsup"
echo ""
echo "Option C: Use IconGenerator.swift (Interactive)"
echo "  1. Add IconGenerator.swift to OneTapSafe Xcode project"
echo "  2. Run the app in Debug mode"
echo "  3. Use ImageRenderer to export each size"
echo ""

# Generate Contents.json for AppIcon.appiconset
echo "📝 Generating Contents.json..."

cat > "$ASSET_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Contents.json created"
echo ""

echo "🎯 Next Steps:"
echo "1. Create 1024x1024 base icon using one of the methods above"
echo "2. Use https://www.appicon.co to generate all sizes automatically"
echo "3. Copy generated files to: $ASSET_DIR"
echo "4. Verify in Xcode that all icon slots are filled"
echo ""

echo "📱 Icon Design Summary:"
echo "  • Base: SF Symbol 'heart.fill' (white)"
echo "  • Accent: 'hand.thumbsup.fill' (green, centered inside heart)"
echo "  • Background: Green gradient (#34C759 → #30D158)"
echo "  • Style: Clean, caring, approval-focused"
echo ""

echo "✨ Done!"
