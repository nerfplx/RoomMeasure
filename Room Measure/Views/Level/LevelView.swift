import SwiftUI
import CoreMotion

struct LevelView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var motionManager = LevelMotionManager()
    @State private var orientation = UIDevice.current.orientation

    private var backgroundColor: Color {
        if abs(motionManager.totalAngle) < 0.5 {
            return Color.green.opacity(0.3)
        } else {
            return Color.black
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: backgroundColor)

                GridPattern()
                    .opacity(0.4)

                LightArea(
                    yOffset: motionManager.verticalOffset,
                    angle: motionManager.horizontalAngle,
                    screenHeight: geometry.size.height
                )

                HorizonLine(
                    yOffset: motionManager.verticalOffset,
                    angle: motionManager.horizontalAngle,
                    screenWidth: geometry.size.width
                )

                VStack {
                    Spacer()
                    Text(String(format: "%.0f°", abs(motionManager.totalAngle)))
                        .font(.system(size: 140, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Spacer()
                }

                HStack {
                    SideLine()
                    Spacer()
                    SideLine()
                }
                .padding(.horizontal, 60)
            }
        }
        .statusBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Назад")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            motionManager.startUpdates()
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                orientation = UIDevice.current.orientation
                motionManager.updateOrientation(orientation)
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    NavigationStack {
        LevelView()
    }
}
