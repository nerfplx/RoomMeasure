import SwiftUI

struct GridPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = size.width / 4

            for i in 0..<5 {
                let x = CGFloat(i) * spacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
            }

            let horizontalCount = Int(size.height / spacing) + 2
            for i in 0..<horizontalCount {
                let y = CGFloat(i) * spacing
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
            }
        }
    }
}

struct LightArea: View {
    let yOffset: CGFloat
    let angle: Double
    let screenHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
                .shadow(color: .white.opacity(0.15), radius: 20, y: -10)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 + yOffset + geometry.size.height
                )
                .rotationEffect(.degrees(-angle))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: yOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: angle)
        }
    }
}

struct HorizonLine: View {
    let yOffset: CGFloat
    let angle: Double
    let screenWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.white)
                .frame(width: geometry.size.width * 2, height: 2)
                .shadow(color: .white.opacity(0.5), radius: 3)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 + yOffset
                )
                .rotationEffect(.degrees(-angle))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: yOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: angle)
        }
    }
}

struct SideLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 80, height: 2.5)
    }
}
