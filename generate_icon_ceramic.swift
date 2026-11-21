import Cocoa

func createCeramicLuxuryYouTubeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // 1. macOS 官方标准 Squircle 几何参数 (1024 坐标系：824x824 居中)
    let squircleSize = size * 0.82
    let origin = (size - squircleSize) / 2.0
    let squircleRect = CGRect(x: origin, y: origin, width: squircleSize, height: squircleSize)
    let cornerRadius = squircleSize * 0.225
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // 2. 底层环境遮挡与下落投影 (macOS 白瓷专属柔和双层物理阴影)
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.035),
        blur: size * 0.060,
        color: NSColor(calibratedRed: 0.15, green: 0.18, blue: 0.22, alpha: 0.32).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor(white: 0.95, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.012),
        blur: size * 0.020,
        color: NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.15, alpha: 0.22).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor(white: 0.95, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    // 3. 剪裁到 Squircle 内部绘制白瓷材质
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()

    // 3.1 极简温润象牙白瓷渐变 (Ivory Porcelain Ceramic Gradient)
    let ceramicColors = [
        NSColor(calibratedRed: 0.985, green: 0.988, blue: 0.992, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.940, green: 0.945, blue: 0.955, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.885, green: 0.895, blue: 0.910, alpha: 1.0).cgColor
    ] as CFArray
    let ceramicGradient = CGGradient(colorsSpace: colorSpace, colors: ceramicColors, locations: [0.0, 0.50, 1.0])!
    context.drawLinearGradient(
        ceramicGradient,
        start: CGPoint(x: squircleRect.minX + squircleSize * 0.25, y: squircleRect.maxY),
        end: CGPoint(x: squircleRect.maxX - squircleSize * 0.25, y: squircleRect.minY),
        options: []
    )

    // 3.2 陶瓷表面柔和弧光反射 (Smooth Ceramic Glaze Sheen)
    let sheenColors = [
        NSColor(calibratedWhite: 1.0, alpha: 0.65).cgColor,
        NSColor(calibratedWhite: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    let sheenGrad = CGGradient(colorsSpace: colorSpace, colors: sheenColors, locations: [0.0, 1.0])!
    context.drawRadialGradient(
        sheenGrad,
        startCenter: CGPoint(x: squircleRect.minX + squircleSize * 0.35, y: squircleRect.maxY - squircleSize * 0.20),
        startRadius: 0,
        endCenter: CGPoint(x: squircleRect.minX + squircleSize * 0.35, y: squircleRect.maxY - squircleSize * 0.20),
        endRadius: squircleSize * 0.75,
        options: []
    )

    // 4. 悬浮纯净红宝石播放牌 (Floating Radiant Ruby Crystal Badge)
    let badgeWidth = squircleSize * 0.58
    let badgeHeight = badgeWidth * 0.70
    let badgeX = (size - badgeWidth) / 2.0
    let badgeY = (size - badgeHeight) / 2.0
    let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
    let badgeRadius = badgeHeight * 0.28
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: badgeRadius, cornerHeight: badgeRadius, transform: nil)

    // 4.1 在纯白瓷表面投射的鲜艳红色氛围散焦光晕 (Ambient Crimson Caustics on Porcelain)
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.028),
        blur: size * 0.050,
        color: NSColor(calibratedRed: 0.95, green: 0.05, blue: 0.20, alpha: 0.40).cgColor
    )
    context.addPath(badgePath)
    context.setFillColor(NSColor(calibratedRed: 0.9, green: 0.05, blue: 0.15, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    // 4.2 物理级近身环境接触阴影
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.012),
        blur: size * 0.022,
        color: NSColor(calibratedRed: 0.25, green: 0.05, blue: 0.08, alpha: 0.30).cgColor
    )
    context.addPath(badgePath)
    context.setFillColor(NSColor(calibratedRed: 0.8, green: 0.05, blue: 0.15, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    // 4.3 绘制通透红宝石晶体
    context.saveGState()
    context.addPath(badgePath)
    context.clip()

    let rubyColors = [
        NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.30, alpha: 1.0).cgColor, // 烈焰亮红顶光
        NSColor(calibratedRed: 0.92, green: 0.06, blue: 0.15, alpha: 1.0).cgColor, // 纯正经典 YouTube 晶红
        NSColor(calibratedRed: 0.75, green: 0.02, blue: 0.09, alpha: 1.0).cgColor, // 深邃宝石红
        NSColor(calibratedRed: 0.52, green: 0.00, blue: 0.06, alpha: 1.0).cgColor  // 皇家暗红底座
    ] as CFArray
    let rubyGradient = CGGradient(colorsSpace: colorSpace, colors: rubyColors, locations: [0.0, 0.35, 0.75, 1.0])!
    context.drawLinearGradient(
        rubyGradient,
        start: CGPoint(x: badgeRect.midX - badgeWidth * 0.15, y: badgeRect.maxY),
        end: CGPoint(x: badgeRect.midX + badgeWidth * 0.15, y: badgeRect.minY),
        options: []
    )

    // 4.4 晶体顶部弧光棱镜反光 (Crystalline Glass Highlight)
    let glossPath = CGMutablePath()
    glossPath.move(to: CGPoint(x: badgeRect.minX, y: badgeRect.maxY - badgeRadius * 0.75))
    glossPath.addCurve(
        to: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY - badgeRadius * 0.75),
        control1: CGPoint(x: badgeRect.minX + badgeWidth * 0.3, y: badgeRect.maxY - badgeHeight * 0.42),
        control2: CGPoint(x: badgeRect.maxX - badgeWidth * 0.3, y: badgeRect.maxY - badgeHeight * 0.42)
    )
    glossPath.addLine(to: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY))
    glossPath.addLine(to: CGPoint(x: badgeRect.minX, y: badgeRect.maxY))
    glossPath.closeSubpath()

    let glossColors = [
        NSColor(calibratedWhite: 1.0, alpha: 0.45).cgColor,
        NSColor(calibratedWhite: 1.0, alpha: 0.02).cgColor
    ] as CFArray
    let glossGrad = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0])!

    context.saveGState()
    context.addPath(glossPath)
    context.clip()
    context.drawLinearGradient(
        glossGrad,
        start: CGPoint(x: badgeRect.midX, y: badgeRect.maxY),
        end: CGPoint(x: badgeRect.midX, y: badgeRect.maxY - badgeHeight * 0.42),
        options: []
    )
    context.restoreGState()

    // 4.5 晶体边缘倒角反光内描边
    context.addPath(badgePath)
    context.setLineWidth(size * 0.0035)
    context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.65).cgColor)
    context.strokePath()

    context.restoreGState() // 退出 badge 剪裁

    // 5. 纯白瓷浮雕 3D 播放三角 (Pure Ivory Porcelain 3D Play Glyph)
    context.saveGState()
    let triWidth = badgeWidth * 0.34
    let triHeight = triWidth * 1.15
    let triCenterX = badgeRect.midX + triWidth * 0.07 // 几何光学微调使其绝对视觉居中
    let triCenterY = badgeRect.midY

    let p1 = CGPoint(x: triCenterX - triWidth * 0.42, y: triCenterY + triHeight * 0.5)
    let p2 = CGPoint(x: triCenterX + triWidth * 0.58, y: triCenterY)
    let p3 = CGPoint(x: triCenterX - triWidth * 0.42, y: triCenterY - triHeight * 0.5)

    let triCornerRadius = triWidth * 0.12
    let triPath = CGMutablePath()
    triPath.move(to: CGPoint(x: p1.x, y: p1.y - triCornerRadius))
    triPath.addArc(tangent1End: p1, tangent2End: p2, radius: triCornerRadius)
    triPath.addArc(tangent1End: p2, tangent2End: p3, radius: triCornerRadius)
    triPath.addArc(tangent1End: p3, tangent2End: p1, radius: triCornerRadius)
    triPath.closeSubpath()

    // 5.1 播放三角投射在红宝石床上的深红暗影
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.010),
        blur: size * 0.016,
        color: NSColor(calibratedRed: 0.35, green: 0.0, blue: 0.05, alpha: 0.60).cgColor
    )

    // 5.2 白瓷三角材质渐变
    context.saveGState()
    context.addPath(triPath)
    context.clip()

    let triColors = [
        NSColor(calibratedWhite: 1.0, alpha: 1.0).cgColor,
        NSColor(calibratedWhite: 0.95, alpha: 1.0).cgColor,
        NSColor(calibratedWhite: 0.88, alpha: 1.0).cgColor
    ] as CFArray
    let triGrad = CGGradient(colorsSpace: colorSpace, colors: triColors, locations: [0.0, 0.65, 1.0])!
    context.drawLinearGradient(
        triGrad,
        start: CGPoint(x: triCenterX, y: triCenterY + triHeight * 0.5),
        end: CGPoint(x: triCenterX, y: triCenterY - triHeight * 0.5),
        options: []
    )
    context.restoreGState()

    // 5.3 三角微晶边缘高光
    context.addPath(triPath)
    context.setLineWidth(size * 0.002)
    context.setStrokeColor(NSColor(white: 1.0, alpha: 0.85).cgColor)
    context.strokePath()

    context.restoreGState()

    // 6. 外层白瓷 Squircle 精雕倒角边缘 (Apple 0.5pt 双重倒角内描边)
    context.addPath(squirclePath)
    context.setLineWidth(size * 0.0025)
    context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.80).cgColor)
    context.strokePath()

    context.restoreGState() // 退出 squircle 剪裁

    image.unlockFocus()
    return image
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_ceramic_1024.png"
let img = createCeramicLuxuryYouTubeIcon(size: 1024)

if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: outputPath))
    print("Ceramic Luxury Icon generated at: \(outputPath)")
}
