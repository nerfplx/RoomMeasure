import SwiftUI
import SwiftData

struct ObjectMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var coordinator = ObjectMeasurementCoordinator()

    var targetProject: MeasurementProject? = nil
    var targetRoom: Room? = nil
    var showCloseButton: Bool = false
    var bottomInsetObject3D: CGFloat = 0

    @State private var state: InteractionState = .idle
    @State private var fixedRect: CGRect? = nil
    @State private var showSaveSheet = false


    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ARViewRepresentable(coordinator: coordinator)
                    .ignoresSafeArea()

                if let rect = displayRect {
                    let screenRect = denormalized(rect, in: size)
                    let confirmed  = isConfirmed
                    DragSelectionOverlay(rect: screenRect, confirmed: confirmed,
                                        measurement: coordinator.currentMeasurement)
                    if confirmed {
                        ResizeHandles(rect: screenRect, handleSize: AppSpacing.handleSize)
                    }
                }

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(mainGesture(in: size))

                VStack {
                    topBar
                    Spacer()
                    bottomBar(in: size)
                }
            }
        }
        .onAppear { coordinator.startSession() }
        .onDisappear { coordinator.stopSession() }
        .sheet(isPresented: $showSaveSheet) {
            if let m = coordinator.currentMeasurement {
                ObjectMeasurementSaveSheet(
                    measurement: m,
                    targetProject: targetProject,
                    targetRoom: targetRoom,
                    modelContext: modelContext,
                    onSaved: { dismiss() }
                )
            }
        }
    }

    private var displayRect: CGRect? {
        switch state {
        case .idle:                   return fixedRect
        case .creating(let s, let c): return makeRect(s, c)
        case .confirming(let r):      return r
        case .resizing(_, let orig):  return fixedRect ?? orig
        case .moving:                 return fixedRect
        }
    }

    private var isConfirmed: Bool {
        switch state {
        case .confirming, .resizing, .moving: return true
        case .idle where fixedRect != nil:    return true
        default:                              return false
        }
    }

    private func mainGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                let loc = value.location
                switch state {
                case .idle:
                    if let rect = fixedRect {
                        let n = normalized(loc, in: size)
                        if let edge = hitEdge(at: n, rect: rect, size: size) {
                            state = .resizing(edge: edge, original: rect)
                        } else if rect.contains(n) {
                            state = .moving(startDrag: n, originalRect: rect)
                        } else {
                            fixedRect = nil
                            coordinator.clearMeasurement()
                            let s = normalized(value.startLocation, in: size)
                            let c = normalized(loc, in: size)
                            state = .creating(start: s, current: c)
                            coordinator.updateMeasurement(normRect: makeRect(s, c), viewSize: size)
                        }
                    } else {
                        let s = normalized(value.startLocation, in: size)
                        let c = normalized(loc, in: size)
                        state = .creating(start: s, current: c)
                        coordinator.updateMeasurement(normRect: makeRect(s, c), viewSize: size)
                    }

                case .creating(let start, _):
                    let c = normalized(loc, in: size)
                    state = .creating(start: start, current: c)
                    coordinator.updateMeasurement(normRect: clampRect(makeRect(start, c)), viewSize: size)

                case .resizing(let edge, let original):
                    let newRect = clampRect(applyResize(edge: edge, to: original,
                                                        at: normalized(loc, in: size)))
                    fixedRect = newRect
                    coordinator.updateMeasurement(normRect: newRect, viewSize: size)

                case .confirming:
                    if let rect = fixedRect {
                        let n = normalized(loc, in: size)
                        if let edge = hitEdge(at: n, rect: rect, size: size) {
                            state = .resizing(edge: edge, original: rect)
                        } else if rect.contains(n) {
                            state = .moving(startDrag: n, originalRect: rect)
                        }
                    }

                case .moving(let startDrag, let originalRect):
                    let n = normalized(loc, in: size)
                    let moved = CGRect(
                        x: originalRect.minX + n.x - startDrag.x,
                        y: originalRect.minY + n.y - startDrag.y,
                        width: originalRect.width, height: originalRect.height
                    )
                    fixedRect = clampRect(moved)
                    coordinator.updateMeasurement(normRect: clampRect(moved), viewSize: size)
                }
            }
            .onEnded { value in
                switch state {
                case .creating(let start, _):
                    let r = clampRect(makeRect(start, normalized(value.location, in: size)))
                    if r.width > 0.03 && r.height > 0.03 {
                        fixedRect = r
                        state = .confirming(rect: r)
                        coordinator.finalizeMeasurement(normRect: r, viewSize: size)
                    } else {
                        state = .idle
                        coordinator.clearMeasurement()
                    }
                case .resizing, .moving:
                    if let r = fixedRect {
                        state = .confirming(rect: r)
                        coordinator.finalizeMeasurement(normRect: r, viewSize: size)
                    }
                default: break
                }
            }
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
                .padding(.leading, 16)
            }
            Spacer()
            if let hint = coordinator.trackingHint {
                Text(hint)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
            }
            if showCloseButton {
                Spacer().frame(width: 56)
            }
        }
        .padding(.horizontal, showCloseButton ? 0 : 20).padding(.top, 16)
    }

    @ViewBuilder
    private func bottomBar(in size: CGSize) -> some View {
        let hasMeasurement = coordinator.currentMeasurement != nil
        let hasRect = fixedRect != nil || isConfirmed

        let text: String = {
            switch state {
            case .idle where fixedRect == nil:
                return coordinator.surfaceDetected
                    ? LocalizedKey.objectMeasureHint.localized
                    : LocalizedKey.arStatusInitializing.localized
            case .creating:
                return LocalizedKey.arInstructionSecond.localized
            default:
                if let m = coordinator.currentMeasurement {
                    return UnitHelper.size(m.width, m.height)
                }
                return LocalizedKey.roomScanProcessing.localized
            }
        }()

        HStack(spacing: 20) {
            if hasRect {
                Button {
                    state = .idle; fixedRect = nil; coordinator.clearMeasurement()
                    HapticManager.impact(.light)
                } label: {
                    ZStack {
                        Circle().fill(.black.opacity(0.55)).frame(width: 48, height: 48)
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 0.15), value: text)

            if hasRect {
                Button {
                    HapticManager.impact(.medium)
                    showSaveSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(hasMeasurement ? Color.green : Color.gray.opacity(0.6))
                            .frame(width: 48, height: 48)
                            .shadow(color: hasMeasurement ? .green.opacity(0.4) : .clear, radius: 6)
                        if hasMeasurement {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(!hasMeasurement)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.bottom, AppSpacing.bottomInsetObject3D * 2)
        .animation(.spring(response: 0.3), value: hasRect)
        .animation(.easeInOut(duration: 0.2), value: hasMeasurement)
    }
}

extension ObjectMeasurementView {

    func hitEdge(at point: CGPoint, rect: CGRect, size: CGSize) -> ResizeEdge? {
        let hw = AppSpacing.handleSize / size.width
        let hh = AppSpacing.handleSize / size.height
        let corners: [(ResizeEdge, CGPoint)] = [
            (.topLeft,     CGPoint(x: rect.minX, y: rect.minY)),
            (.topRight,    CGPoint(x: rect.maxX, y: rect.minY)),
            (.bottomLeft,  CGPoint(x: rect.minX, y: rect.maxY)),
            (.bottomRight, CGPoint(x: rect.maxX, y: rect.maxY)),
        ]
        for (edge, corner) in corners {
            if abs(point.x - corner.x) < hw && abs(point.y - corner.y) < hh { return edge }
        }
        let edges: [(ResizeEdge, Bool)] = [
            (.top,    abs(point.y - rect.minY) < hh && point.x > rect.minX && point.x < rect.maxX),
            (.bottom, abs(point.y - rect.maxY) < hh && point.x > rect.minX && point.x < rect.maxX),
            (.left,   abs(point.x - rect.minX) < hw && point.y > rect.minY && point.y < rect.maxY),
            (.right,  abs(point.x - rect.maxX) < hw && point.y > rect.minY && point.y < rect.maxY),
        ]
        return edges.first(where: { $0.1 })?.0
    }

    func applyResize(edge: ResizeEdge, to rect: CGRect, at point: CGPoint) -> CGRect {
        var minX = rect.minX, minY = rect.minY, maxX = rect.maxX, maxY = rect.maxY
        let minSize: CGFloat = 0.05
        switch edge {
        case .topLeft:     minX = min(point.x, maxX - minSize); minY = min(point.y, maxY - minSize)
        case .topRight:    maxX = max(point.x, minX + minSize); minY = min(point.y, maxY - minSize)
        case .bottomLeft:  minX = min(point.x, maxX - minSize); maxY = max(point.y, minY + minSize)
        case .bottomRight: maxX = max(point.x, minX + minSize); maxY = max(point.y, minY + minSize)
        case .top:         minY = min(point.y, maxY - minSize)
        case .bottom:      maxY = max(point.y, minY + minSize)
        case .left:        minX = min(point.x, maxX - minSize)
        case .right:       maxX = max(point.x, minX + minSize)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func normalized(_ pt: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: max(0, min(1, pt.x / size.width)),
                y: max(0, min(1, pt.y / size.height)))
    }

    func denormalized(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(x: rect.minX * size.width,  y: rect.minY * size.height,
               width: rect.width * size.width, height: rect.height * size.height)
    }

    func makeRect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(b.x - a.x), height: abs(b.y - a.y))
    }

    func clampRect(_ rect: CGRect) -> CGRect {
        let x = max(0, min(rect.minX, 1 - rect.width))
        let y = max(0, min(rect.minY, 1 - rect.height))
        return CGRect(x: x, y: y,
                      width: min(rect.width, 1 - x),
                      height: min(rect.height, 1 - y))
    }
}
