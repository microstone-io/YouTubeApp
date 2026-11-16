import Cocoa

func createYouTubeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let rect = CGRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84)
    let cornerRadius = size * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.04), blur: size * 0.07, color: NSColor(calibratedRed: 0.7, green: 0, blue: 0, alpha: 0.35).cgColor)

    // Red Gradient Background (YouTube Brand Red)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(calibratedRed: 1.0, green: 0.15, blue: 0.15, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.85, green: 0.05, blue: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!

    context.addPath(path)
    context.clip()
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    context.restoreGState()

    // Subtle inner bevel gloss highlight
    context.saveGState()
    context.addPath(path)
    context.setLineWidth(size * 0.015)
    context.setStrokeColor(NSColor(white: 1.0, alpha: 0.25).cgColor)
    context.strokePath()
    context.restoreGState()

    // White Play Button Triangle in Center
    context.saveGState()
    let triPath = CGMutablePath()
    let centerX = size * 0.52
    let centerY = size * 0.50
    let triWidth = size * 0.28
    let triHeight = size * 0.32

    let p1 = CGPoint(x: centerX - triWidth * 0.42, y: centerY + triHeight * 0.5)
    let p2 = CGPoint(x: centerX + triWidth * 0.58, y: centerY)
    let p3 = CGPoint(x: centerX - triWidth * 0.42, y: centerY - triHeight * 0.5)

    triPath.move(to: p1)
    triPath.addLine(to: p2)
    triPath.addLine(to: p3)
    triPath.closeSubpath()

    // Triangle drop shadow
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.04, color: NSColor(calibratedWhite: 0, alpha: 0.3).cgColor)

    context.addPath(triPath)
    context.setFillColor(NSColor.white.cgColor)
    context.fillPath()
    context.restoreGState()

    image.unlockFocus()
    return image
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
let img = createYouTubeIcon(size: 1024)

if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: outputPath))
    print("Icon generated at: \(outputPath)")
}
