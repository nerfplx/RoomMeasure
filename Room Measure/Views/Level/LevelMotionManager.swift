import CoreMotion
import UIKit

class LevelMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var verticalOffset: CGFloat = 0.0
    @Published var horizontalAngle: Double = 0.0
    @Published var totalAngle: Double = 0.0

    private var currentOrientation: UIDeviceOrientation = .portrait

    init() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        currentOrientation = UIDevice.current.orientation
    }

    func updateOrientation(_ orientation: UIDeviceOrientation) {
        currentOrientation = orientation
    }

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            let gravityX = motion.gravity.x
            let gravityY = motion.gravity.y

            var rollAngle: Double = 0.0

            switch self.currentOrientation {
            case .portrait, .portraitUpsideDown:
                rollAngle = asin(gravityX) * 180.0 / .pi
            case .landscapeLeft, .landscapeRight:
                rollAngle = asin(gravityY) * 180.0 / .pi
            default:
                rollAngle = asin(gravityX) * 180.0 / .pi
            }

            DispatchQueue.main.async {
                self.horizontalAngle = rollAngle
                self.verticalOffset = 0.0
                self.totalAngle = abs(rollAngle)
            }
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
