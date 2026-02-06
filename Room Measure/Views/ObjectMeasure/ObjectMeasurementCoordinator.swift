import ARKit
import SwiftUI
import Combine

final class FrameThrottle: @unchecked Sendable {
    private let lock = NSLock()
    private var lastTime: TimeInterval = 0
    let interval: TimeInterval
    init(interval: TimeInterval) { self.interval = interval }
    func shouldProcess(timestamp: TimeInterval) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard timestamp - lastTime >= interval else { return false }
        lastTime = timestamp; return true
    }
}

struct ARViewRepresentable: UIViewRepresentable {
    let coordinator: ObjectMeasurementCoordinator
    func makeUIView(context: Context) -> ARSCNView { coordinator.sceneView }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

@MainActor
final class ObjectMeasurementCoordinator: NSObject, ObservableObject {
    let sceneView = ARSCNView()
    @Published var currentMeasurement: MeasurementResult?
    @Published var surfaceDetected: Bool = false
    @Published var trackingHint: String?

    private let cursorThrottle = FrameThrottle(interval: 0.2)

    func startSession() {
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics = .smoothedSceneDepth
        } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
        }
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stopSession() {
        sceneView.delegate = nil
        sceneView.session.delegate = nil
        sceneView.session.pause()
    }

    private func raycast(at screenPoint: CGPoint) -> simd_float3? {
        for (target, align) in [
            (ARRaycastQuery.Target.existingPlaneGeometry, ARRaycastQuery.TargetAlignment.any),
            (.estimatedPlane, .any)
        ] {
            guard let q = sceneView.raycastQuery(from: screenPoint, allowing: target, alignment: align),
                  let r = sceneView.session.raycast(q).first else { continue }
            let c = r.worldTransform.columns.3
            return simd_float3(c.x, c.y, c.z)
        }
        return nil
    }

    func updateMeasurement(normRect: CGRect, viewSize: CGSize) {
        currentMeasurement = computeMeasurement(normRect: normRect, viewSize: viewSize)
    }

    func finalizeMeasurement(normRect: CGRect, viewSize: CGSize) {
        currentMeasurement = computeMeasurement(normRect: normRect, viewSize: viewSize)
    }

    func clearMeasurement() { currentMeasurement = nil }

    private func computeMeasurement(normRect: CGRect, viewSize: CGSize) -> MeasurementResult? {
        func pt(_ nx: CGFloat, _ ny: CGFloat) -> CGPoint {
            CGPoint(x: nx * viewSize.width, y: ny * viewSize.height)
        }
        let tl = raycast(at: pt(normRect.minX, normRect.minY))
        let tr = raycast(at: pt(normRect.maxX, normRect.minY))
        let bl = raycast(at: pt(normRect.minX, normRect.maxY))
        let br = raycast(at: pt(normRect.maxX, normRect.maxY))
        let tm = raycast(at: pt(normRect.midX, normRect.minY))
        let bm = raycast(at: pt(normRect.midX, normRect.maxY))
        let lm = raycast(at: pt(normRect.minX, normRect.midY))
        let rm = raycast(at: pt(normRect.maxX, normRect.midY))

        var ws: [Float] = [], hs: [Float] = []
        if let a = tl, let b = tr { ws.append(simd_distance(a, b)) }
        if let a = lm, let b = rm { ws.append(simd_distance(a, b)) }
        if let a = bl, let b = br { ws.append(simd_distance(a, b)) }
        if let a = tl, let b = bl { hs.append(simd_distance(a, b)) }
        if let a = tm, let b = bm { hs.append(simd_distance(a, b)) }
        if let a = tr, let b = br { hs.append(simd_distance(a, b)) }

        guard !ws.isEmpty, !hs.isEmpty else { return nil }
        return MeasurementResult(
            screenRect: normRect,
            worldCorners: [tl, tr, br, bl].compactMap { $0 },
            width:  ws.reduce(0, +) / Float(ws.count),
            height: hs.reduce(0, +) / Float(hs.count)
        )
    }

    func checkSurface() {
        surfaceDetected = raycast(at: CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)) != nil
    }

    func applyTrackingHint(_ state: ARCamera.TrackingState) {
        switch state {
        case .normal:       trackingHint = nil
        case .notAvailable: trackingHint = LocalizedKey.arStatusInitializing.localized
        case .limited(let reason):
            switch reason {
            case .initializing:         trackingHint = LocalizedKey.arStatusInitializing.localized
            case .excessiveMotion:      trackingHint = LocalizedKey.arStatusExcessiveMotion.localized
            case .insufficientFeatures: trackingHint = LocalizedKey.arStatusInsufficientFeatures.localized
            case .relocalizing:         trackingHint = LocalizedKey.arStatusRelocalizing.localized
            @unknown default:           trackingHint = nil
            }
        }
    }
}

extension ObjectMeasurementCoordinator: ARSCNViewDelegate {
    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {}
}

extension ObjectMeasurementCoordinator: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard cursorThrottle.shouldProcess(timestamp: frame.timestamp) else { return }
        let trackingState = frame.camera.trackingState
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.applyTrackingHint(trackingState)
            self.checkSurface()
        }
    }
}
