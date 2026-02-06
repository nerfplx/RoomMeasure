import ARKit
import RealityKit
import AVFoundation

class ARMeasurementViewModel: NSObject, ObservableObject, ARSessionDelegate {
    @Published var points: [SIMD3<Float>] = []
    @Published var segments: [MeasurementSegment] = []
    @Published var totalDistance: Float = 0
    @Published var trackingStatus = LocalizedKey.arMeasurementTrackingInitializing.localized
    @Published var autoFlashlightEnabled = true

    private(set) var arView: ARView?
    var pointAnchors: [AnchorEntity] = []
    var lineAnchors:  [AnchorEntity] = []
    var labelAnchors: [AnchorEntity] = []

    private let flashlightManager = FlashlightManager.shared
    private var isCleanedUp = false
    private var captureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video)
    private var lightCheckCounter = 0

    func setupARView(_ arView: ARView) {
        isCleanedUp = false
        self.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = self
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
    }

    func tryDeletePoint(at screenPoint: CGPoint, in arView: ARView) {
        guard !points.isEmpty else { return }
        var closestIndex: Int?
        var closestDistance: Float = 60
        for (index, point) in points.enumerated() {
            guard let screenPos = arView.project(point) else { continue }
            let dx = Float(screenPos.x - screenPoint.x)
            let dy = Float(screenPos.y - screenPoint.y)
            let dist = sqrt(dx * dx + dy * dy)
            if dist < closestDistance { closestIndex = index; closestDistance = dist }
        }
        guard let index = closestIndex else { return }
        deletePoint(at: index)
    }

    private func deletePoint(at index: Int) {
        guard let arView = arView else { return }

        arView.scene.removeAnchor(pointAnchors[index])
        pointAnchors.remove(at: index)
        points.remove(at: index)

        var segmentsToRemove: [Int] = []
        if index > 0             { segmentsToRemove.append(index - 1) }
        if index < segments.count { segmentsToRemove.append(index) }

        for i in segmentsToRemove.sorted(by: >) {
            arView.scene.removeAnchor(lineAnchors[i])
            arView.scene.removeAnchor(labelAnchors[i])
            lineAnchors.remove(at: i)
            labelAnchors.remove(at: i)
            segments.remove(at: i)
        }

        if index > 0 && index < points.count {
            let newSegment = MeasurementSegment(start: points[index - 1], end: points[index])
            segments.insert(newSegment, at: index - 1)
            drawDashedLine(from: points[index - 1], to: points[index])
            drawDistanceLabel(from: points[index - 1], to: points[index], distance: newSegment.distance)
            lineAnchors.insert(lineAnchors.removeLast(), at: index - 1)
            labelAnchors.insert(labelAnchors.removeLast(), at: index - 1)
        }
        totalDistance = segments.reduce(0) { $0 + $1.distance }
    }

    func addPoint() {
        guard let arView = arView else { return }
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let results = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .any)
        guard let raycastResult = results.first else { print("⚠️ No raycast result"); return }

        let position = raycastResult.worldTransform.columns.3
        let point = SIMD3<Float>(position.x, position.y, position.z)

        if let lastPoint = points.last {
            let segment = MeasurementSegment(start: lastPoint, end: point)
            segments.append(segment)
            drawDashedLine(from: lastPoint, to: point)
            drawDistanceLabel(from: lastPoint, to: point, distance: segment.distance)
            totalDistance = segments.reduce(0) { $0 + $1.distance }
        }
        points.append(point)
        addPointMarker(at: point, index: points.count)
    }

    func undoLastPoint() {
        guard !points.isEmpty, let arView = arView else { return }
        if let last = pointAnchors.last { arView.scene.removeAnchor(last); pointAnchors.removeLast() }
        if !segments.isEmpty {
            if let last = lineAnchors.last  { arView.scene.removeAnchor(last); lineAnchors.removeLast() }
            if let last = labelAnchors.last { arView.scene.removeAnchor(last); labelAnchors.removeLast() }
            segments.removeLast()
            totalDistance = segments.reduce(0) { $0 + $1.distance }
        }
        points.removeLast()
    }

    func clearAll() {
        guard let arView = arView else { return }
        for anchor in pointAnchors { arView.scene.removeAnchor(anchor) }
        for anchor in lineAnchors  { arView.scene.removeAnchor(anchor) }
        for anchor in labelAnchors { arView.scene.removeAnchor(anchor) }
        pointAnchors.removeAll(); lineAnchors.removeAll(); labelAnchors.removeAll()
        points.removeAll(); segments.removeAll()
        totalDistance = 0
    }

    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        flashlightManager.turnOff()
        guard let arView = arView else { return }
        arView.session.pause()
        arView.session.delegate = nil
        for anchor in pointAnchors { arView.scene.removeAnchor(anchor) }
        for anchor in lineAnchors  { arView.scene.removeAnchor(anchor) }
        for anchor in labelAnchors { arView.scene.removeAnchor(anchor) }
        arView.scene.anchors.removeAll()
        pointAnchors.removeAll(); lineAnchors.removeAll(); labelAnchors.removeAll()
        points.removeAll(); segments.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.totalDistance = 0
            self?.trackingStatus = LocalizedKey.arMeasurementTrackingStopped.localized
        }
        self.arView = nil
    }

    deinit { cleanup() }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        lightCheckCounter += 1
        guard lightCheckCounter >= 30 else { return }
        lightCheckCounter = 0
        monitorAmbientLight()
    }

    private func monitorAmbientLight() {
        guard autoFlashlightEnabled else {
            if flashlightManager.isFlashlightOn { flashlightManager.turnOff() }
            return
        }
        guard let device = captureDevice else { return }
        let brightness = flashlightManager.calculateBrightness(
            iso: device.iso, exposureDuration: device.exposureDuration.seconds
        )
        flashlightManager.updateFlashlight(shouldAutoEnable: autoFlashlightEnabled, currentBrightness: brightness)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCleanedUp else { return }
            switch camera.trackingState {
            case .normal:         self.trackingStatus = LocalizedKey.arMeasurementTrackingReady.localized
            case .notAvailable:   self.trackingStatus = LocalizedKey.arMeasurementTrackingUnavailable.localized
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:      self.trackingStatus = LocalizedKey.arMeasurementTrackingExcessiveMotion.localized
                case .insufficientFeatures: self.trackingStatus = LocalizedKey.arMeasurementTrackingInsufficientFeatures.localized
                case .initializing:         self.trackingStatus = LocalizedKey.arMeasurementTrackingInitializing.localized
                case .relocalizing:         self.trackingStatus = LocalizedKey.arMeasurementTrackingRelocalizing.localized
                @unknown default:           self.trackingStatus = LocalizedKey.arMeasurementTrackingLimited.localized
                }
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCleanedUp else { return }
            self.trackingStatus = LocalizedKey.arMeasurementTrackingError.localized
            print("❌ AR Session error: \(error.localizedDescription)")
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        flashlightManager.turnOff()
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCleanedUp else { return }
            self.trackingStatus = LocalizedKey.arMeasurementTrackingInterrupted.localized
        }
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCleanedUp else { return }
            self.trackingStatus = LocalizedKey.arMeasurementTrackingReady.localized
        }
    }
}

extension ARMeasurementViewModel {

    func addPointMarker(at position: SIMD3<Float>, index: Int) {
        guard let arView = arView else { return }

        let anchor = AnchorEntity(world: position)
        let dot = ModelEntity(
            mesh: .generatePlane(width: 0.012, height: 0.012, cornerRadius: 0.006),
            materials: [UnlitMaterial(color: .white)]
        )
        dot.components.set(BillboardComponent())
        anchor.addChild(dot)
        arView.scene.addAnchor(anchor)
        pointAnchors.append(anchor)
    }

    func drawDashedLine(from start: SIMD3<Float>, to end: SIMD3<Float>) {
        guard let arView = arView else { return }

        let distance  = simd_distance(start, end)
        let direction = normalize(end - start)
        let dashLength: Float = 0.015
        let gapLength:  Float = 0.010
        let stepLength = dashLength + gapLength

        let anchor = AnchorEntity(world: start)
        var currentDist: Float = 0

        while currentDist < distance {
            let segStart   = start + direction * currentDist
            let actualDash = min(dashLength, distance - currentDist)
            guard actualDash > 0.001 else { break }

            let midpoint = segStart + direction * (actualDash / 2)
            let dash = ModelEntity(
                mesh: .generateBox(width: 0.003, height: actualDash, depth: 0.003),
                materials: [SimpleMaterial(color: .white, isMetallic: false)]
            )

            let up    = SIMD3<Float>(0, 1, 0)
            let dotP  = dot(up, direction)
            let angle = acos(max(-1, min(1, dotP)))
            let rotation: simd_quatf
            if abs(angle) < 0.001 {
                rotation = simd_quatf(angle: 0,   axis: SIMD3<Float>(1, 0, 0))
            } else if abs(angle - .pi) < 0.001 {
                rotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
            } else {
                rotation = simd_quatf(angle: angle, axis: normalize(cross(up, direction)))
            }

            dash.position    = midpoint - start
            dash.orientation = rotation
            anchor.addChild(dash)
            currentDist += stepLength
        }

        arView.scene.addAnchor(anchor)
        lineAnchors.append(anchor)
    }

    func drawDistanceLabel(from start: SIMD3<Float>, to end: SIMD3<Float>, distance: Float) {
        guard let arView = arView else { return }

        let midpoint = (start + end) / 2
        let anchor   = AnchorEntity(world: midpoint)

        let background = ModelEntity(
            mesh: .generatePlane(width: 0.08, height: 0.025, cornerRadius: 0.005),
            materials: [UnlitMaterial(color: UIColor(white: 0, alpha: 0.65))]
        )
        background.components.set(BillboardComponent())

        let textMesh = MeshResource.generateText(
            UnitHelper.lengthFull(distance),
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.018, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textEntity = ModelEntity(mesh: textMesh, materials: [UnlitMaterial(color: .white)])
        let bounds     = textEntity.visualBounds(relativeTo: nil)
        textEntity.position = SIMD3<Float>(
            -(bounds.max.x - bounds.min.x) / 2,
            -(bounds.max.y - bounds.min.y) / 2,
            0.002
        )

        background.addChild(textEntity)
        background.position.y += 0.02
        anchor.addChild(background)

        arView.scene.addAnchor(anchor)
        labelAnchors.append(anchor)
    }
}
