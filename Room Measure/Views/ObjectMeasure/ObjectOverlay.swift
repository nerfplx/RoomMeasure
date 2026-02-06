import SwiftUI

struct ResizeHandles: View {
    let rect: CGRect
    let handleSize: CGFloat

    private let corners: [(CGFloat, CGFloat)]    = [(0,0),(1,0),(0,1),(1,1)]
    private let midHandles: [(CGFloat, CGFloat)]  = [(0.5,0),(0.5,1),(0,0.5),(1,0.5)]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let (fx, fy) = corners[i]
                Circle().fill(Color.white)
                    .frame(width: handleSize, height: handleSize)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .position(x: rect.minX + rect.width * fx,
                              y: rect.minY + rect.height * fy)
            }
            ForEach(0..<4, id: \.self) { i in
                let (fx, fy) = midHandles[i]
                RoundedRectangle(cornerRadius: 4).fill(Color.white)
                    .frame(width: fy == 0.5 ? 6 : handleSize * 0.75,
                           height: fy == 0.5 ? handleSize * 0.75 : 6)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .position(x: rect.minX + rect.width * fx,
                              y: rect.minY + rect.height * fy)
            }
        }
    }
}

struct DragSelectionOverlay: View {
    let rect: CGRect
    let confirmed: Bool
    let measurement: MeasurementResult?

    private var color: Color { confirmed ? .green : .white }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(confirmed ? 0.08 : 0.05))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            Rectangle()
                .strokeBorder(color, lineWidth: confirmed ? 2.5 : 1.5)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            CornerMarkers(rect: rect, color: color, len: 20)

            if confirmed, let m = measurement {
                DimLabel(text: UnitHelper.length(m.width))
                    .position(x: rect.midX, y: max(rect.minY - 18, 18))

                DimLabel(text: UnitHelper.length(m.height))
                    .rotationEffect(.degrees(90))
                    .position(x: min(rect.maxX + 28, UIScreen.main.bounds.width - 20),
                              y: rect.midY)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: confirmed)
    }
}

struct CornerMarkers: View {
    let rect: CGRect
    let color: Color
    let len: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            for (x, y, sx, sy) in [
                (rect.minX, rect.minY,  1.0,  1.0),
                (rect.maxX, rect.minY, -1.0,  1.0),
                (rect.minX, rect.maxY,  1.0, -1.0),
                (rect.maxX, rect.maxY, -1.0, -1.0)
            ] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                var p = Path()
                p.move(to:    CGPoint(x: x,          y: y + sy * len))
                p.addLine(to: CGPoint(x: x,          y: y))
                p.addLine(to: CGPoint(x: x + sx*len, y: y))
                ctx.stroke(p, with: .color(color),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }
}

struct DimLabel: View {
    let text: String
    var dimmed: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(dimmed ? .white.opacity(0.6) : .white)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(.black.opacity(dimmed ? 0.45 : 0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
