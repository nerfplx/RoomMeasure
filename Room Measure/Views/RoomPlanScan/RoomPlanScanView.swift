import SwiftUI
import RoomPlan
import SwiftData

struct RoomPlanScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var roomCaptureController = RoomCaptureController()
    @State private var showingResults = false
    @State private var capturedRoom: CapturedRoom?
    @State private var hasStarted = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoFlashlight") private var autoFlashlight = true

    let targetProject: MeasurementProject?
    let targetRoom: Room?
    var showCloseButton: Bool = false
    var topPadding: CGFloat = AppSpacing.cameraTopPadding

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            RoomCaptureViewRepresentable(
                roomCaptureController: roomCaptureController,
                onCaptureComplete: handleCaptureComplete
            )
            .ignoresSafeArea()
            .opacity(roomCaptureController.isScanning ? 1 : AppOpacity.cameraHidden)

            if roomCaptureController.isScanning {
                VStack {
                    scanningTopBar
                    Spacer()
                    scanningControlButtons
                }
            }

            if !hasStarted {
                RoomScanOnboardingView(
                    targetProject: targetProject,
                    targetRoom: targetRoom,
                    showCloseButton: showCloseButton,
                    onDismiss: { dismiss() },
                    onStart: handleStart
                )
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear  { roomCaptureController.autoFlashlightEnabled = autoFlashlight }
        .onChange(of: autoFlashlight) { _, v in roomCaptureController.autoFlashlightEnabled = v }
        .onDisappear { roomCaptureController.cleanup() }
        .sheet(isPresented: $showingResults, onDismiss: {
            withAnimation(AppAnimation.onboardingDismiss) { hasStarted = false }
            capturedRoom = nil
        }) {
            if let room = capturedRoom {
                RoomResultsView(
                    capturedRoom: room,
                    targetProject: targetProject,
                    targetRoom: targetRoom,
                    onDismiss: { showingResults = false }
                )
            }
        }
    }

    private var scanningTopBar: some View {
        HStack {
            if showCloseButton {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.55))
                            .frame(width: 40, height: 40)
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            Spacer()
            Text(roomCaptureController.statusText)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Capsule().fill(Color.black.opacity(AppOpacity.overlayBg)))
            Spacer()
            if showCloseButton {
                Spacer().frame(width: 56)
            }
        }
        .padding(AppSpacing.md)
        .padding(.top, topPadding)
    }
    
    private var scanningControlButtons: some View {
        Button(action: handleStop) {
            VStack(spacing: AppSpacing.xs + 2) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                Text(LocalizedKey.roomScanStop.localized)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, AppSpacing.toolbarBottomInset)
    }

    private func handleStart() {
        withAnimation(AppAnimation.onboardingAppear) { hasStarted = true }
        if hapticFeedback { HapticManager.impact(.medium) }
        roomCaptureController.startSession()
    }

    private func handleStop() {
        if hapticFeedback { HapticManager.impact(.medium) }
        roomCaptureController.stopSession()
    }

    private func handleCaptureComplete(room: CapturedRoom) {
        if hapticFeedback { HapticManager.notification(.success) }
        capturedRoom = room
        showingResults = true
    }
}

#Preview {
    RoomPlanScanView(targetProject: nil, targetRoom: nil)
        .modelContainer(for: MeasurementProject.self, inMemory: true)
}
