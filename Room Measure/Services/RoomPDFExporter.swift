import UIKit
import RoomPlan

struct RoomPDFExporter {

    static func generate(
        wallInfos:    [WallInfo],
        doorInfos:    [DoorWindowInfo],
        windowInfos:  [DoorWindowInfo],
        dimDisplay:   (height: Float, area: Float)?,
        capturedRoom: CapturedRoom?,
        measurements: [SingleMeasurement] = []
    ) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: LocalizedKey.roomResultsTitle.localized]

        let pageW: CGFloat = 595.2, pageH: CGFloat = 841.8, margin: CGFloat = 50
        let contentW = pageW - margin * 2
        let planH    = contentW * 0.6

        let planImage = FloorPlanRenderer.render(
            wallInfos: wallInfos, doorInfos: doorInfos, windowInfos: windowInfos,
            size: CGSize(width: contentW, height: planH), isExport: true
        )

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
            format: format
        )

        return renderer.pdfData { ctx in
            ctx.beginPage()

            let titleFont  = UIFont.boldSystemFont(ofSize: 22)
            let headerFont = UIFont.boldSystemFont(ofSize: 15)
            let bodyFont   = UIFont.systemFont(ofSize: 13)
            let smallFont  = UIFont.systemFont(ofSize: 11)
            var y: CGFloat = 40

            func drawText(_ text: String, font: UIFont, color: UIColor = .black, x: CGFloat = margin) {
                text.draw(
                    at: CGPoint(x: x, y: y),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
            }

            func pageBreakIfNeeded(needed: CGFloat) {
                if y + needed > pageH - margin {
                    ctx.beginPage()
                    y = 40
                }
            }

            drawText(LocalizedKey.roomResultsTitle.localized, font: titleFont)
            y += 36

            let df = DateFormatter()
            df.dateStyle = .long; df.timeStyle = .short
            drawText(df.string(from: Date()), font: bodyFont, color: .darkGray)
            y += 32

            if let d = dimDisplay {
                           drawText(
                               "\(LocalizedKey.roomHeight.localized): \(UnitHelper.length(d.height))   " +
                               "\(LocalizedKey.roomArea.localized): \(UnitHelper.area(d.area))",
                               font: bodyFont
                           )
                           y += 28
                       }

            if let cr = capturedRoom {
                pageBreakIfNeeded(needed: CGFloat(22 + cr.walls.count * 18 + 60))
                drawText(LocalizedKey.roomWalls.localized, font: headerFont)
                y += 22
                for (i, wall) in cr.walls.enumerated() {
                    drawText(
                        "\(i + 1). \(UnitHelper.length(wall.dimensions.x)) × \(UnitHelper.length(wall.dimensions.y))",
                        font: bodyFont, x: margin + 10
                    )
                    y += 18
                }
                y += 8
                if !cr.doors.isEmpty {
                    drawText("\(LocalizedKey.roomDoors.localized): \(cr.doors.count)", font: bodyFont)
                    y += 20
                }
                if !cr.windows.isEmpty {
                    drawText("\(LocalizedKey.roomWindows.localized): \(cr.windows.count)", font: bodyFont)
                    y += 20
                }
                y += 12
            }

            if !measurements.isEmpty {
                pageBreakIfNeeded(needed: 44)
                drawText(LocalizedKey.roomMeasurements.localized, font: headerFont)
                y += 22

                let objectMeasurements = measurements.filter { $0.objectHeight != nil }
                let arMeasurements     = measurements.filter { $0.objectHeight == nil }

                if !objectMeasurements.isEmpty {
                    pageBreakIfNeeded(needed: 20)
                    drawText(LocalizedKey.measurementObjectScan.localized, font: bodyFont, color: .systemPurple)
                    y += 18

                    for (i, m) in objectMeasurements.enumerated() {
                        pageBreakIfNeeded(needed: 40)

                        let wStr = UnitHelper.length(m.distance)
                        let hStr: String = m.objectHeight.map { UnitHelper.length($0) } ?? "—"

                        drawText("\(i + 1). \(m.name)", font: bodyFont)
                        y += 16

                        drawText(
                            "Ш: \(wStr)  ×  В: \(hStr)",
                            font: smallFont, color: .systemPurple, x: margin + 10
                        )
                        y += 14

                        if let notes = m.notes, !notes.isEmpty {
                            drawText(notes, font: smallFont, color: .darkGray, x: margin + 10)
                            y += 14
                        }
                        y += 6
                    }
                    y += 6
                }

                if !arMeasurements.isEmpty {
                    pageBreakIfNeeded(needed: 20)
                    drawText(LocalizedKey.measurementManual.localized, font: bodyFont, color: .systemBlue)
                    y += 18

                    for (i, m) in arMeasurements.enumerated() {
                        pageBreakIfNeeded(needed: 34)

                        let distStr = UnitHelper.length(m.distance)
                        
                        drawText("\(i + 1). \(m.name)  —  \(distStr)", font: bodyFont)
                        y += 16

                        if let notes = m.notes, !notes.isEmpty {
                            drawText(notes, font: smallFont, color: .darkGray, x: margin + 10)
                            y += 14
                        }
                        y += 6
                    }
                    y += 6
                }

                y += 6
            }

            pageBreakIfNeeded(needed: planH + 40)
            drawText(LocalizedKey.floorPlanTitle.localized, font: headerFont)
            y += 20

            let planRect = CGRect(x: margin, y: y, width: contentW, height: planH)
            planImage.draw(in: planRect)
            ctx.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            ctx.cgContext.stroke(planRect)
        }
    }
}
