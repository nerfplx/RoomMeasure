import SwiftUI
import SwiftData

struct ARMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var arViewModel = ARMeasurementViewModel()
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoFlashlight") private var autoFlashlight = true

    let targetProject: MeasurementProject?
    let targetRoom: Room?
    var showCloseButton: Bool = false
    var topPadding: CGFloat = 50

    @State private var showingSaveDialog = false
    @State private var selectedSegmentIndex: Int? = nil

    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .ignoresSafeArea()
                .onAppear  { arViewModel.autoFlashlightEnabled = autoFlashlight }
                .onChange(of: autoFlashlight) { _, v in arViewModel.autoFlashlightEnabled = v }

            GeometryReader { geo in
                Image(systemName: "circle.dotted")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.5), radius: 3)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                segmentsPanel
                instructionsView
                controlButtons
            }
        }
        .ignoresSafeArea()
        .onDisappear { arViewModel.cleanup() }
        .sheet(isPresented: $showingSaveDialog) {
            SaveMeasurementSheet(
                distance: selectedSegmentDistance,
                targetProject: targetProject,
                targetRoom: targetRoom,
                modelContext: modelContext,
                onSaved: {
                    showingSaveDialog = false
                    selectedSegmentIndex = nil
                },
                onCancel: {
                    showingSaveDialog = false
                    selectedSegmentIndex = nil
                }
            )
        }
    }

    private var selectedSegmentDistance: Float {
        guard let i = selectedSegmentIndex, i < arViewModel.segments.count else {
            return arViewModel.totalDistance
        }
        return arViewModel.segments[i].distance
    }

    private var topBar: some View {
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
                .padding(.leading, AppSpacing.md)
            }
            Spacer()
            if arViewModel.totalDistance > 0 {
                Text(UnitHelper.sigma(arViewModel.totalDistance))
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue.opacity(0.7)))
            }
            Text(arViewModel.trackingStatus)
                .font(.caption).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.6)))
            if showCloseButton {
                Spacer().frame(width: 56)
            } else {
                Spacer()
            }
        }
        .padding()
        .padding(.top, topPadding)
    }
    
    @ViewBuilder
    private var segmentsPanel: some View {
        if !arViewModel.segments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { triggerSave(index: nil) }) {
                        segmentChip(label: "Σ", value: UnitHelper.lengthFull(arViewModel.totalDistance), color: .green)
                    }
                    ForEach(Array(arViewModel.segments.enumerated()), id: \.offset) { i, seg in
                        Button(action: { triggerSave(index: i) }) {
                            segmentChip(label: "\(i + 1)", value: UnitHelper.lengthFull(seg.distance), color: .blue)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
    }

    private func segmentChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.7))
            Text(value).font(.system(.caption, design: .monospaced)).fontWeight(.semibold).foregroundColor(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.7)))
    }

    private func triggerSave(index: Int?) {
        selectedSegmentIndex = index
        showingSaveDialog = true
        if hapticFeedback { HapticManager.impact(.light) }
    }

    @ViewBuilder
    private var instructionsView: some View {
        let hint = arViewModel.points.isEmpty
            ? LocalizedKey.arMeasurementFirstPoint.localized
            : LocalizedKey.arMeasurementSecondPoint.localized
        Text(hint)
            .font(.headline).foregroundColor(.white)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
            .padding(.bottom, 4)
    }

    private var controlButtons: some View {
        HStack(spacing: 32) {
            Button(action: {
                if hapticFeedback { HapticManager.impact(.medium) }
                withAnimation { arViewModel.undoLastPoint() }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 44)).foregroundColor(.orange)
                    Text(LocalizedKey.projectsCancel.localized).font(.caption).foregroundColor(.white)
                }
            }
            .disabled(arViewModel.points.isEmpty)
            .opacity(arViewModel.points.isEmpty ? 0.4 : 1)

            Button(action: {
                if hapticFeedback { HapticManager.impact(.medium) }
                withAnimation { arViewModel.addPoint() }
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 64, height: 64)
                        Image(systemName: "plus").font(.system(size: 28, weight: .bold)).foregroundColor(.blue)
                    }
                    Text(LocalizedKey.arMeasurementPoint.localized).font(.caption).foregroundColor(.white)
                }
            }

            Button(action: {
                if hapticFeedback { HapticManager.impact(.medium) }
                withAnimation { arViewModel.clearAll() }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 44)).foregroundColor(.red)
                    Text(LocalizedKey.arMeasurementClear.localized).font(.caption).foregroundColor(.white)
                }
            }
            .disabled(arViewModel.points.isEmpty)
            .opacity(arViewModel.points.isEmpty ? 0.4 : 1)
        }
        .padding(.bottom, 110)
    }
}

#Preview {
    ARMeasurementView(targetProject: nil, targetRoom: nil)
        .modelContainer(for: MeasurementProject.self, inMemory: true)
}
