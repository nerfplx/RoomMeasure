import UIKit
import SwiftData

struct FloorPlanRenderer {

    static func render(
        wallInfos:   [WallInfo],
        doorInfos:   [DoorWindowInfo],
        windowInfos: [DoorWindowInfo],
        size: CGSize,
        isExport: Bool = false
    ) -> UIImage {
        guard !wallInfos.isEmpty else { return UIImage() }

        let cfg: PlanStyle = isExport ? ExportStyle(size: size) : AppStyle(size: size)

        var allPoints: [CGPoint] = []
        for w in wallInfos   { allPoints.append(contentsOf: endpoints(cx: w.centerX, cz: w.centerZ, nx: w.directionX, nz: w.directionZ, half: w.width/2)) }
        for d in doorInfos   { allPoints.append(contentsOf: endpoints(cx: d.centerX, cz: d.centerZ, nx: d.directionX, nz: d.directionZ, half: d.width/2)) }
        for w in windowInfos { allPoints.append(contentsOf: endpoints(cx: w.centerX, cz: w.centerZ, nx: w.directionX, nz: w.directionZ, half: w.width/2)) }

        let angle = dominantAngle(wallInfos: wallInfos)
        let t     = makeTransform(points: allPoints, size: size, padding: cfg.padding, rotAngle: angle)
        let canvasCenter = CGPoint(x: size.width / 2, y: size.height / 2)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext

            cfg.bgColor.setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            if isExport {
                cg.setStrokeColor(UIColor.black.cgColor)
                cg.setLineWidth(1.5)
                cg.stroke(CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4))
            }

            for (i, wall) in wallInfos.enumerated() {
                let pts = endpoints(cx: wall.centerX, cz: wall.centerZ,
                                    nx: wall.directionX, nz: wall.directionZ, half: wall.width/2)
                let p1 = applyTransform(t, to: pts[0])
                let p2 = applyTransform(t, to: pts[1])
                drawWall(p1: p1, p2: p2, index: i + 1, width: wall.width,
                         cfg: cfg, canvasCenter: canvasCenter, in: cg)
            }

            for door in doorInfos {
                let pts = endpoints(cx: door.centerX, cz: door.centerZ,
                                    nx: door.directionX, nz: door.directionZ, half: door.width/2)
                drawOpening(p1: applyTransform(t, to: pts[0]),
                            p2: applyTransform(t, to: pts[1]),
                            isDoor: true, cfg: cfg, in: cg)
            }

            for window in windowInfos {
                let pts = endpoints(cx: window.centerX, cz: window.centerZ,
                                    nx: window.directionX, nz: window.directionZ, half: window.width/2)
                drawOpening(p1: applyTransform(t, to: pts[0]),
                            p2: applyTransform(t, to: pts[1]),
                            isDoor: false, cfg: cfg, in: cg)
            }

            drawLegend(hasDoors: !doorInfos.isEmpty, hasWindows: !windowInfos.isEmpty, cfg: cfg, in: cg)
        }
    }

     struct AppStyle: PlanStyle {
        let size: CGSize
        var bgColor:      UIColor  { .secondarySystemBackground }
        var wallColor:    UIColor  { UIColor(white: 0.18, alpha: 1) }
        var doorColor:    UIColor  { .systemOrange }
        var windowColor:  UIColor  { .systemBlue }
        var dimColor:     UIColor  { UIColor(white: 0.40, alpha: 1) }
        var dimBgColor:   UIColor  { UIColor.secondarySystemBackground.withAlphaComponent(0.88) }
        var legendColor:  UIColor  { .secondaryLabel }
        var wallThick:    CGFloat  { 7 }
        var dimOffset:    CGFloat  { 20 }
        var fontSize:     CGFloat  { scaledFontSize }
        var padding:      CGFloat  { scaledPadding }
    }

     struct ExportStyle: PlanStyle {
        let size: CGSize
        var bgColor:      UIColor  { .white }
        var wallColor:    UIColor  { .black }
        var doorColor:    UIColor  { UIColor(red: 0.8, green: 0.4, blue: 0, alpha: 1) }
        var windowColor:  UIColor  { UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1) }
        var dimColor:     UIColor  { UIColor(white: 0.25, alpha: 1) }
        var dimBgColor:   UIColor  { UIColor.white.withAlphaComponent(0.92) }
        var legendColor:  UIColor  { UIColor(white: 0.3, alpha: 1) }
        var wallThick:    CGFloat  { max(3, size.width / 120) }
        var dimOffset:    CGFloat  { max(22, size.width / 28) }
        var fontSize:     CGFloat  { scaledFontSize }
        var padding:      CGFloat  { scaledPadding }
    }

    private protocol PlanStyle {
        var size: CGSize   { get }
        var bgColor:     UIColor { get }
        var wallColor:   UIColor { get }
        var doorColor:   UIColor { get }
        var windowColor: UIColor { get }
        var dimColor:    UIColor { get }
        var dimBgColor:  UIColor { get }
        var legendColor: UIColor { get }
        var wallThick:   CGFloat { get }
        var dimOffset:   CGFloat { get }
        var fontSize:    CGFloat { get }
        var padding:     CGFloat { get }
    }

    private static func scaledFont(size: CGSize, base: CGFloat = 11) -> CGFloat {
        let scale = min(size.width, size.height) / 300
        return max(9, min(base * scale, 28))
    }

    private static func drawWall(
        p1: CGPoint, p2: CGPoint,
        index: Int, width: Float,
        cfg: PlanStyle, canvasCenter: CGPoint,
        in ctx: CGContext
    ) {
        ctx.setStrokeColor(cfg.wallColor.cgColor)
        ctx.setLineWidth(cfg.wallThick)
        ctx.setLineCap(.round)
        ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()

        let perp   = perpendicular(p1, p2)
        let offset = outerOffset(p1: p1, p2: p2, perp: perp, center: canvasCenter, dist: cfg.dimOffset)
        let d1 = CGPoint(x: p1.x + offset.x, y: p1.y + offset.y)
        let d2 = CGPoint(x: p2.x + offset.x, y: p2.y + offset.y)

        ctx.setStrokeColor(cfg.dimColor.withAlphaComponent(0.45).cgColor)
        ctx.setLineWidth(0.75)
        ctx.move(to: p1); ctx.addLine(to: d1); ctx.strokePath()
        ctx.move(to: p2); ctx.addLine(to: d2); ctx.strokePath()

        ctx.setStrokeColor(cfg.dimColor.cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: d1); ctx.addLine(to: d2); ctx.strokePath()

        let tickLen = cfg.dimOffset * 0.3
        drawTick(at: d1, dir: perp, len: tickLen, color: cfg.dimColor, in: ctx)
        drawTick(at: d2, dir: perp, len: tickLen, color: cfg.dimColor, in: ctx)

        let mid   = CGPoint(x: (d1.x+d2.x)/2, y: (d1.y+d2.y)/2)
        let label = "\(index).  \(UnitHelper.lengthFull(width))"
        let font  = UIFont.systemFont(ofSize: cfg.fontSize, weight: .medium)
        drawText(label, at: mid, angle: lineAngle(d1, d2), font: font,
                 color: cfg.dimColor, bgColor: cfg.dimBgColor, in: ctx)
    }

    private static func drawOpening(
        p1: CGPoint, p2: CGPoint,
        isDoor: Bool, cfg: PlanStyle,
        in ctx: CGContext
    ) {
        let color = isDoor ? cfg.doorColor : cfg.windowColor

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(cfg.wallThick * 0.85)
        ctx.setLineCap(.butt)
        ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()

        if isDoor {
            let len = hypot(p2.x - p1.x, p2.y - p1.y)
            let ang = atan2(p2.y - p1.y, p2.x - p1.x)
            ctx.setStrokeColor(color.withAlphaComponent(0.35).cgColor)
            ctx.setLineWidth(max(0.5, cfg.wallThick * 0.12))
            ctx.setLineDash(phase: 0, lengths: [5, 4])
            ctx.addArc(center: p1, radius: len, startAngle: ang, endAngle: ang - .pi/2, clockwise: true)
            ctx.strokePath()
            ctx.setLineDash(phase: 0, lengths: [])
        }
    }

    private static func drawLegend(
        hasDoors: Bool, hasWindows: Bool,
        cfg: PlanStyle, in ctx: CGContext
    ) {
        guard hasDoors || hasWindows else { return }
        var items: [(UIColor, String)] = []
        if hasDoors   { items.append((cfg.doorColor,   LocalizedKey.floorPlanDoor.localized))   }
        if hasWindows { items.append((cfg.windowColor, LocalizedKey.floorPlanWindow.localized)) }

        let font    = UIFont.systemFont(ofSize: max(9, cfg.fontSize * 0.88))
        let lineH   = cfg.fontSize + 6
        let margin: CGFloat = 10
        let y = cfg.size.height - lineH * CGFloat(items.count) - margin
        var x: CGFloat = margin

        for (color, label) in items {
            ctx.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: x, y: y + lineH/2 - 2, width: 16, height: 4))
            x += 20

            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: cfg.legendColor]
            (label as NSString).draw(at: CGPoint(x: x, y: y + lineH/2 - font.lineHeight/2), withAttributes: attrs)
            x += (label as NSString).size(withAttributes: attrs).width + 14
        }
    }

    private typealias T = (scale: CGFloat, offX: CGFloat, offY: CGFloat, angle: CGFloat)

    private static func dominantAngle(wallInfos: [WallInfo]) -> Float {
        guard let longest = wallInfos.max(by: { $0.width < $1.width }) else { return 0 }
        var a = atan2(longest.directionZ, longest.directionX)
        while a >  Float.pi / 4 { a -= Float.pi / 2 }
        while a < -Float.pi / 4 { a += Float.pi / 2 }
        return a
    }

    private static func makeTransform(points: [CGPoint], size: CGSize, padding: CGFloat, rotAngle: Float) -> T {
        let a = CGFloat(-rotAngle)
        let rotated = points.map { pt in
            CGPoint(x: pt.x * cos(a) - pt.y * sin(a),
                    y: pt.x * sin(a) + pt.y * cos(a))
        }
        let xs = rotated.map(\.x), ys = rotated.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let wW = maxX - minX, wH = maxY - minY
        guard wW > 0.001, wH > 0.001 else { return (100, size.width/2, size.height/2, a) }

        let dW = size.width  - padding * 2
        let dH = size.height - padding * 2
        let scale = min(dW / wW, dH / wH)
        let offX  = padding + (dW - wW * scale) / 2 - minX * scale
        let offY  = padding + (dH - wH * scale) / 2 - minY * scale
        return (scale, offX, offY, a)
    }

    private static func applyTransform(_ t: T, to pt: CGPoint) -> CGPoint {
        let rx = pt.x * cos(t.angle) - pt.y * sin(t.angle)
        let ry = pt.x * sin(t.angle) + pt.y * cos(t.angle)
        return CGPoint(x: rx * t.scale + t.offX, y: ry * t.scale + t.offY)
    }

    private static func endpoints(cx: Float, cz: Float, nx: Float, nz: Float, half: Float) -> [CGPoint] {
        [CGPoint(x: CGFloat(cx - nx*half), y: CGFloat(cz - nz*half)),
         CGPoint(x: CGFloat(cx + nx*half), y: CGFloat(cz + nz*half))]
    }

    private static func perpendicular(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        let dx = p2.x - p1.x, dy = p2.y - p1.y
        let l  = hypot(dx, dy)
        return l > 0.001 ? CGPoint(x: -dy/l, y: dx/l) : CGPoint(x: 0, y: 1)
    }

    private static func outerOffset(p1: CGPoint, p2: CGPoint, perp: CGPoint, center: CGPoint, dist: CGFloat) -> CGPoint {
        let mid  = CGPoint(x: (p1.x+p2.x)/2, y: (p1.y+p2.y)/2)
        let o1   = CGPoint(x: mid.x + perp.x*dist, y: mid.y + perp.y*dist)
        let o2   = CGPoint(x: mid.x - perp.x*dist, y: mid.y - perp.y*dist)
        let far  = hypot(o1.x-center.x, o1.y-center.y) > hypot(o2.x-center.x, o2.y-center.y)
        return far ? CGPoint(x: perp.x*dist, y: perp.y*dist) : CGPoint(x: -perp.x*dist, y: -perp.y*dist)
    }

    private static func drawTick(at p: CGPoint, dir: CGPoint, len: CGFloat, color: UIColor, in ctx: CGContext) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: p.x - dir.x*len, y: p.y - dir.y*len))
        ctx.addLine(to: CGPoint(x: p.x + dir.x*len, y: p.y + dir.y*len))
        ctx.strokePath()
    }

    private static func lineAngle(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        atan2(p2.y - p1.y, p2.x - p1.x)
    }

    private static func drawText(_ text: String, at pt: CGPoint, angle: CGFloat,
                                  font: UIFont, color: UIColor, bgColor: UIColor, in ctx: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str = text as NSString
        let sz  = str.size(withAttributes: attrs)
        ctx.saveGState()
        ctx.translateBy(x: pt.x, y: pt.y)
        var a = angle
        if a >  .pi/2 { a -= .pi }
        if a < -.pi/2 { a += .pi }
        ctx.rotate(by: a)
        bgColor.setFill()
        ctx.fill(CGRect(x: -sz.width/2 - 2, y: -sz.height/2 - 1, width: sz.width+4, height: sz.height+2))
        str.draw(at: CGPoint(x: -sz.width/2, y: -sz.height/2), withAttributes: attrs)
        ctx.restoreGState()
    }
}

private extension FloorPlanRenderer.AppStyle {
    var scaledFontSize: CGFloat { FloorPlanRenderer.scaledFont(size: size) }
    var scaledPadding:  CGFloat { max(40, min(size.width, size.height) * 0.17) }
}

private extension FloorPlanRenderer.ExportStyle {
    var scaledFontSize: CGFloat { FloorPlanRenderer.scaledFont(size: size, base: 13) }
    var scaledPadding:  CGFloat { max(60, min(size.width, size.height) * 0.17) }
}
