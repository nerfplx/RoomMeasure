import SwiftUI

struct MeasurementContainerView: View {
    var initialMode: MeasurementToolMode = .space
    var targetProject: MeasurementProject? = nil
    var targetRoom: Room?     = nil
    
    var body: some View {
        MeasurementScreenView(
            initialMode:   initialMode,
            targetProject: targetProject,
            targetRoom:    targetRoom
        )
    }
}

struct MeasurementScreenView: View {
    let initialMode: MeasurementToolMode
    let targetProject: MeasurementProject?
    let targetRoom: Room?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: MeasurementToolMode
    
    init(initialMode: MeasurementToolMode, targetProject: MeasurementProject?, targetRoom: Room?) {
        self.initialMode   = initialMode
        self.targetProject = targetProject
        self.targetRoom    = targetRoom
        _selectedMode      = State(initialValue: initialMode)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedMode {
                case .space:
                    RoomPlanScanView(targetProject: targetProject, targetRoom: targetRoom)
                case .ruler:
                    ARMeasurementView(targetProject: targetProject, targetRoom: targetRoom)
                case .object3D:
                    ObjectMeasurementView(
                        targetProject: targetProject,
                        targetRoom: targetRoom,
                        showCloseButton: false,
                        bottomInsetObject3D: AppSpacing.bottomInsetObject3D
                    )
                case .level:
                    LevelView()
                }
            }
            .ignoresSafeArea()
            
            MeasurementToolbar(
                selectedMode: $selectedMode,
                onClose: { dismiss() }
            )
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

struct MeasurementToolbar: View {
    @Binding var selectedMode: MeasurementToolMode
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.55))
                        .frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 16)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(MeasurementToolMode.allCases, id: \.rawValue) { mode in
                            ModeTabItem(mode: mode, isSelected: selectedMode == mode) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                    selectedMode = mode
                                }
                                HapticManager.selection()
                            }
                            .id(mode.rawValue)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .onChange(of: selectedMode) { _, mode in
                    withAnimation(.spring(response: 0.35)) {
                        proxy.scrollTo(mode.rawValue, anchor: .center)
                    }
                }
                .onAppear {
                    proxy.scrollTo(selectedMode.rawValue, anchor: .center)
                }
            }
        }
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
        )
        .padding(.bottom, 30)
    }
}

private struct ModeTabItem: View {
    let mode: MeasurementToolMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(systemName: mode.icon)
                    .font(.system(size: isSelected ? 20 : 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                Text(mode.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(width: 84, height: 52)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .padding(.horizontal, 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MeasurementContainerView()
}
