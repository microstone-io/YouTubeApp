import Cocoa

func createLuxuryYouTubeIcon(size: CGFloat) -> NSImage {
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

    // 1. macOS 标准 Squircle 几何参数 (基于 1024 坐标系：824x824 居中)
    let squircleSize = size * 0.82
    let origin = (size - squircleSize) / 2.0
    let squircleRect = CGRect(x: origin, y: origin, width: squircleSize, height: squircleSize)
    let cornerRadius = squircleSize * 0.225
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // 2. 底层环境遮挡与下落投影 (macOS Pro 双层物理阴影)
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.035),
        blur: size * 0.055,
        color: NSColor(white: 0.0, alpha: 0.45).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor(white: 0.1, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.012),
        blur: size * 0.020,
        color: NSColor(white: 0.0, alpha: 0.35).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor(white: 0.1, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    // 3. 剪裁到 Squircle 内部绘制主体材质
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()

    // 3.1 钛黑陶瓷 / 黑曜石基底渐变 (深邃、哑光、微金属质感)
    let baseColors = [
        NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.17, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.10, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let baseGradient = CGGradient(colorsSpace: colorSpace, colors: baseColors, locations: [0.0, 0.45, 1.0])!
    context.drawLinearGradient(
        baseGradient,
        start: CGPoint(x: size * 0.3, y: size * 0.95),
        end: CGPoint(x: size * 0.7, y: size * 0.05),
        options: []
    )

    // 3.2 顶部左上方微光工作室聚光灯 (Studio Light Sheen)
    let spotlightColors = [
        NSColor(calibratedWhite: 1.0, alpha: 0.08).cgColor,
        NSColor(calibratedWhite: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    let spotlightGrad = CGGradient(colorsSpace: colorSpace, colors: spotlightColors, locations: [0.0, 1.0])!
    context.drawRadialGradient(
        spotlightGrad,
        startCenter: CGPoint(x: squircleRect.minX + squircleSize * 0.35, y: squircleRect.maxY - squircleSize * 0.25),
        startRadius: 0,
        endCenter: CGPoint(x: squircleRect.minX + squircleSize * 0.35, y: squircleRect.maxY - squircleSize * 0.25),
        endRadius: squircleSize * 0.8,
        options: []
    )

    // 3.3 底部深红环境光晕 (Ambient Crimson Underglow)
    let glowColors = [
        NSColor(calibratedRed: 1.0, green: 0.05, blue: 0.18, alpha: 0.22).cgColor,
        NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.1, alpha: 0.0).cgColor
    ] as CFArray
    let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0])!
    context.drawRadialGradient(
        glowGrad,
        startCenter: CGPoint(x: size * 0.5, y: size * 0.48),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.5, y: size * 0.48),
        endRadius: squircleSize * 0.65,
        options: []
    )

    // 4. 浮雕中心红宝石播放牌 (Floating Ruby Crystal Play Badge)
    let badgeWidth = squircleSize * 0.58
    let badgeHeight = badgeWidth * 0.70
    let badgeX = (size - badgeWidth) / 2.0
    let badgeY = (size - badgeHeight) / 2.0
    let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
    let badgeRadius = badgeHeight * 0.28
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: badgeRadius, cornerHeight: badgeRadius, transform: nil)

    // 4.1 悬浮徽章的多层投影与红宝石自发光晕
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.025),
        blur: size * 0.045,
        color: NSColor(calibratedRed: 0.95, green: 0.0, blue: 0.15, alpha: 0.45).cgColor
    )
    context.addPath(badgePath)
    context.setFillColor(NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.1, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.015),
        blur: size * 0.020,
        color: NSColor(white: 0.0, alpha: 0.55).cgColor
    )
    context.addPath(badgePath)
    context.setFillColor(NSColor(calibratedRed: 0.7, green: 0.0, blue: 0.1, alpha: 1.0).cgColor)
    context.fillPath()
    context.restoreGState()

    // 4.2 绘制红宝石晶体多段渐变
    context.saveGState()
    context.addPath(badgePath)
    context.clip()

    let rubyColors = [
        NSColor(calibratedRed: 1.0, green: 0.22, blue: 0.28, alpha: 1.0).cgColor, // 烈焰珊瑚红顶光
        NSColor(calibratedRed: 0.92, green: 0.06, blue: 0.16, alpha: 1.0).cgColor, // 纯正 YouTube 红
        NSColor(calibratedRed: 0.72, green: 0.02, blue: 0.10, alpha: 1.0).cgColor, // 深邃胭脂红
        NSColor(calibratedRed: 0.50, green: 0.00, blue: 0.06, alpha: 1.0).cgColor  // 皇家红宝石暗底
    ] as CFArray
    let rubyGradient = CGGradient(colorsSpace: colorSpace, colors: rubyColors, locations: [0.0, 0.35, 0.75, 1.0])!
    context.drawLinearGradient(
        rubyGradient,
        start: CGPoint(x: badgeRect.midX - badgeWidth * 0.2, y: badgeRect.maxY),
        end: CGPoint(x: badgeRect.midX + badgeWidth * 0.1, y: badgeRect.minY),
        options: []
    )

    // 4.3 晶体顶部弧光反光 (Crystalline Specular Highlight)
    let glossPath = CGMutablePath()
    glossPath.move(to: CGPoint(x: badgeRect.minX, y: badgeRect.maxY - badgeRadius * 0.8))
    glossPath.addCurve(
        to: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY - badgeRadius * 0.8),
        control1: CGPoint(x: badgeRect.minX + badgeWidth * 0.3, y: badgeRect.maxY - badgeHeight * 0.45),
        control2: CGPoint(x: badgeRect.maxX - badgeWidth * 0.3, y: badgeRect.maxY - badgeHeight * 0.45)
    )
    glossPath.addLine(to: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY))
    glossPath.addLine(to: CGPoint(x: badgeRect.minX, y: badgeRect.maxY))
    glossPath.closeSubpath()

    let glossColors = [
        NSColor(calibratedWhite: 1.0, alpha: 0.35).cgColor,
        NSColor(calibratedWhite: 1.0, alpha: 0.02).cgColor
    ] as CFArray
    let glossGrad = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0])!

    context.saveGState()
    context.addPath(glossPath)
    context.clip()
    context.drawLinearGradient(
        glossGrad,
        start: CGPoint(x: badgeRect.midX, y: badgeRect.maxY),
        end: CGPoint(x: badgeRect.midX, y: badgeRect.maxY - badgeHeight * 0.45),
        options: []
    )
    context.restoreGState()

    // 4.4 晶体边缘倒角高光与暗边内描边
    context.addPath(badgePath)
    context.setLineWidth(size * 0.0035)
    context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.55).cgColor)
    context.strokePath()

    context.restoreGState() // 退出 badge 剪裁

    // 5. 白金 / 象牙白 3D 播放三角 (Pure Platinum 3D Play Glyph)
    context.saveGState()
    let triWidth = badgeWidth * 0.34
    let triHeight = triWidth * 1.15
    let triCenterX = badgeRect.midX + triWidth * 0.07 // 几何光学微调，使其视觉绝对居中
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

    // 5.1 三角形真实微投影
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.012),
        blur: size * 0.018,
        color: NSColor(calibratedRed: 0.35, green: 0.0, blue: 0.05, alpha: 0.55).cgColor
    )

    // 5.2 三角形质感渐变 (白金纯净微光)
    context.saveGState()
    context.addPath(triPath)
    context.clip()

    let triColors = [
        NSColor(calibratedWhite: 1.0, alpha: 1.0).cgColor,
        NSColor(calibratedWhite: 0.94, alpha: 1.0).cgColor,
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

    // 5.3 三角形极细倒角高光
    context.addPath(triPath)
    context.setLineWidth(size * 0.002)
    context.setStrokeColor(NSColor(white: 1.0, alpha: 0.75).cgColor)
    context.strokePath()

    context.restoreGState()

    // 6. 外层 Squircle 边缘精雕发丝纹 (Apple Pro 0.5pt 双重金属倒角边缘)
    context.addPath(squirclePath)
    context.setLineWidth(size * 0.003)
    context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.22).cgColor)
    context.strokePath()

    context.restoreGState() // 退出 squircle 剪裁

    image.unlockFocus()
    return image
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_pro_1024.png"
let img = createLuxuryYouTubeIcon(size: 1024)

if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: outputPath))
    print("Luxury Pro Icon generated at: \(outputPath)")
}
