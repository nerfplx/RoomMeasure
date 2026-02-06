import SwiftUI
import SwiftData

struct RoomScanOnboardingView: View {
    let targetProject: MeasurementProject?
    let targetRoom: Room?
    let showCloseButton: Bool
    let onDismiss: () -> Void
    let onStart: () -> Void

    @State private var animateIcon = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.onboardingGradientTop, AppColors.onboardingGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RoomGridBackground()
                .opacity(AppOpacity.gridLines)

            if showCloseButton {
                VStack {
                    HStack {
                        Button(action: onDismiss) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.55))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, AppSpacing.md)
                        .padding(.top)
                        Spacer()
                    }
                    Spacer()
                }
            }

            VStack(spacing: 0) {
                Spacer()
                iconView
                    .padding(.bottom, AppSpacing.onboardingIconBottom)
                titleView
                    .padding(.bottom, AppSpacing.onboardingTitleBottom)
                instructionsList
                    .padding(.bottom, AppSpacing.onboardingListBottom)
                if targetProject != nil || targetRoom != nil {
                    destinationBadge
                        .padding(.bottom, AppSpacing.onboardingDestBottom)
                }
                startButton
                Spacer()
            }
        }
        .onAppear { animateIcon = true }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(AppOpacity.iconFill))
                .frame(width: AppSpacing.onboardingIconSize, height: AppSpacing.onboardingIconSize)
                .scaleEffect(animateIcon ? AppSpacing.onboardingPulseInner : 1.0)

            Circle()
                .strokeBorder(Color.blue.opacity(AppOpacity.iconRing), lineWidth: AppBorders.thin)
                .frame(width: AppSpacing.onboardingIconSize, height: AppSpacing.onboardingIconSize)
                .scaleEffect(animateIcon ? AppSpacing.onboardingPulseOuter : 1.0)
                .opacity(animateIcon ? 0 : AppOpacity.high)

            Image(systemName: "cube.transparent.fill")
                .font(.system(size: AppSpacing.onboardingIconInner, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.blue.opacity(AppOpacity.iconGradientEnd)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .animation(AppAnimation.onboardingPulse, value: animateIcon)
    }

    private var titleView: some View {
        Text(LocalizedKey.projectDetail3DScan.localized)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }

    private var instructionsList: some View {
        VStack(spacing: AppSpacing.onboardingInstructionSpacing) {
            InstructionRow(icon: "arrow.up.and.down.and.arrow.left.and.right",
                           text: LocalizedKey.roomScanInstructionMove.localized)
            InstructionRow(icon: "light.max",
                           text: LocalizedKey.measurementTipLighting.localized)
            InstructionRow(icon: "clock",
                           text: LocalizedKey.projectDetailTime.localized)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var destinationBadge: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue.opacity(AppOpacity.high))
                .font(.caption)
            if let project = targetProject {
                Text(project.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(AppOpacity.textSecondary))
            }
            if let room = targetRoom {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(AppOpacity.textTertiary))
                Image(systemName: "house.fill")
                    .foregroundColor(.green.opacity(AppOpacity.high))
                    .font(.caption)
                Text(room.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(AppOpacity.textSecondary))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Capsule().fill(.white.opacity(AppOpacity.ghost)))
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: AppSpacing.sm + 2) {
                Image(systemName: "record.circle")
                    .font(.system(size: 18, weight: .semibold))
                Text(LocalizedKey.roomScanStart.localized)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.onboardingButtonPadV)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(AppOpacity.buttonGradientEnd)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
            .shadow(color: .blue.opacity(AppOpacity.shadowBlue), radius: AppSpacing.md - 4, x: 0, y: AppSpacing.xs + 2)
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md - 2) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue.opacity(AppOpacity.high + 0.1))
                .frame(width: AppSpacing.onboardingInstructionIconW)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(AppOpacity.textSecondary))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

struct RoomGridBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Canvas { ctx, _ in
                let step = Int(AppSpacing.onboardingGridStep)
                for i in stride(from: 0, through: Int(h), by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: CGFloat(i)))
                    path.addLine(to: CGPoint(x: w, y: CGFloat(i)))
                    ctx.stroke(path, with: .color(.white), lineWidth: AppBorders.thin * 0.5)
                }
                for i in stride(from: 0, through: Int(w), by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: CGFloat(i), y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i), y: h))
                    ctx.stroke(path, with: .color(.white), lineWidth: AppBorders.thin * 0.5)
                }
            }
        }
        .ignoresSafeArea()
    }
}
