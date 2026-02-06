import UIKit
import SwiftData

enum ProjectPDFExporter {
    
    static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm"
        return f.string(from: Date())
    }
    
    static func generate(for project: MeasurementProject) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: project.name,
            kCGPDFContextCreator as String: "RoomMeasure"
        ]
        
        let pageW: CGFloat = 595.2, pageH: CGFloat = 841.8, margin: CGFloat = 50
        let contentW = pageW - margin * 2
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
            format: format
        )
        
        return renderer.pdfData { ctx in
            ctx.beginPage()
            
            let titleFont  = UIFont.boldSystemFont(ofSize: 22)
            let headerFont = UIFont.boldSystemFont(ofSize: 15)
            let subFont    = UIFont.boldSystemFont(ofSize: 13)
            let bodyFont   = UIFont.systemFont(ofSize: 13)
            let smallFont  = UIFont.systemFont(ofSize: 11)
            var y: CGFloat = 50
            
            func draw(_ text: String, font: UIFont, color: UIColor = .black, indent: CGFloat = 0) {
                text.draw(at: CGPoint(x: margin + indent, y: y),
                          withAttributes: [.font: font, .foregroundColor: color])
            }
            
            func pageBreakIfNeeded(needed: CGFloat) {
                if y + needed > pageH - margin { ctx.beginPage(); y = 50 }
            }
            
            func separator() {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: margin + contentW, y: y))
                UIColor.lightGray.withAlphaComponent(0.5).setStroke()
                path.lineWidth = 0.5; path.stroke(); y += 10
            }
            
            draw(project.name, font: titleFont); y += 34
            let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short
            draw(df.string(from: Date()), font: bodyFont, color: .darkGray); y += 28
            separator()
            
            draw(LocalizedKey.projectDetailStatistics.localized, font: headerFont); y += 22
            draw("\(LocalizedKey.projectRooms.localized): \(project.totalRooms)", font: bodyFont, color: .darkGray, indent: 10); y += 18
            draw("\(LocalizedKey.roomMeasurements.localized): \(project.totalMeasurements)", font: bodyFont, color: .darkGray, indent: 10); y += 18
            
            if project.totalArea > 0 {
                draw("\(LocalizedKey.projectTotalArea.localized): \(UnitHelper.area(project.totalArea))", font: bodyFont, color: .darkGray, indent: 10); y += 18
            }
            if project.totalVolume > 0 {
                draw("\(LocalizedKey.projectDetailTotalVolume.localized): \(UnitHelper.volume(project.totalVolume))", font: bodyFont, color: .darkGray, indent: 10); y += 18
            }
            y += 10
            
            guard !project.rooms.isEmpty else { return }
            separator()
            draw(LocalizedKey.projectRooms.localized, font: headerFont); y += 24
            
            for (index, room) in project.rooms.enumerated() {
                pageBreakIfNeeded(needed: 80)
                draw("\(index + 1). \(room.name)", font: subFont); y += 18
                
                if let dims = room.roomDimensions {
                    draw("\(LocalizedKey.roomArea.localized): \(UnitHelper.area(dims.area))   \(LocalizedKey.roomHeight.localized): \(UnitHelper.length(dims.height))",
                         font: smallFont, color: .darkGray, indent: 14); y += 15
                }
                
                let allMeasurements = room.measurements
                if !allMeasurements.isEmpty {
                    let objectM = allMeasurements.filter { $0.objectHeight != nil }
                    let arM     = allMeasurements.filter { $0.objectHeight == nil }
                    
                    if !objectM.isEmpty {
                        draw(LocalizedKey.measurementObjectScan.localized, font: smallFont, color: .systemPurple, indent: 14); y += 14
                        for m in objectM {
                            pageBreakIfNeeded(needed: 28)
                            let wStr = UnitHelper.length(m.distance)
                            let hStr = m.objectHeight.map { UnitHelper.length($0) } ?? "—"
                            draw("• \(m.name)  —  Ш: \(wStr) × В: \(hStr)", font: smallFont, color: .darkGray, indent: 22); y += 14
                            if let notes = m.notes, !notes.isEmpty {
                                draw(notes, font: smallFont, color: .lightGray, indent: 30); y += 12
                            }
                        }
                    }
                    
                    if !arM.isEmpty {
                        draw(LocalizedKey.measurementManual.localized, font: smallFont, color: .systemBlue, indent: 14); y += 14
                        for m in arM {
                            pageBreakIfNeeded(needed: 26)
                            draw("• \(m.name)  —  \(UnitHelper.length(m.distance))", font: smallFont, color: .darkGray, indent: 22); y += 14
                            if let notes = m.notes, !notes.isEmpty {
                                draw(notes, font: smallFont, color: .lightGray, indent: 30); y += 12
                            }
                        }
                    }
                }
                
                if !room.wallInfos.isEmpty {
                    let planW: CGFloat = contentW * 0.6
                    let planH: CGFloat = planW * 0.55
                    pageBreakIfNeeded(needed: planH + 30)
                    draw(LocalizedKey.floorPlanTitle.localized, font: smallFont, color: .darkGray, indent: 14); y += 14
                    let planImage = FloorPlanRenderer.render(
                        wallInfos: room.wallInfos, doorInfos: room.doorInfos, windowInfos: room.windowInfos,
                        size: CGSize(width: planW, height: planH), isExport: true
                    )
                    let planRect = CGRect(x: margin + 14, y: y, width: planW, height: planH)
                    planImage.draw(in: planRect)
                    ctx.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                    ctx.cgContext.setLineWidth(0.5)
                    ctx.cgContext.stroke(planRect)
                    y += planH + 10
                }
                y += 12
            }
        }
    }
}
