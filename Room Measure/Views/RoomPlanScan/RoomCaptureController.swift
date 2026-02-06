import Foundation
import RoomPlan
import AVFoundation

class RoomCaptureController: NSObject, ObservableObject, RoomCaptureViewDelegate {
    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init()
    }

    func encode(with coder: NSCoder) {}

    @Published var isScanning = false
    @Published var statusText = LocalizedKey.roomScanReady.localized
    @Published var autoFlashlightEnabled = true

    private var captureView: RoomCaptureView?
    private var completion: ((CapturedRoom) -> Void)?
    private let flashlightManager = FlashlightManager.shared
    private var lightMonitorTimer: Timer?
    private lazy var captureDevice = AVCaptureDevice.default(for: .video)
    private var isCleanedUp = false


    func setupCaptureView(_ view: RoomCaptureView, completion: @escaping (CapturedRoom) -> Void) {
        isCleanedUp = false
        self.captureView = view
        self.completion = completion
        view.delegate = self
    }

    func startSession() {
        guard let captureView = captureView else { return }
        guard RoomCaptureSession.isSupported else {
            print("❌ RoomPlan не поддерживается")
            statusText = LocalizedKey.roomScanNotSupported.localized
            return
        }

        checkCameraPermission { [weak self] granted in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if granted {
                    let config = RoomCaptureSession.Configuration()
                    captureView.captureSession.run(configuration: config)
                    self.isScanning = true
                    self.statusText = LocalizedKey.roomScanScanning.localized
                    self.startLightMonitoring()
                    print("✅ RoomPlan session started")
                } else {
                    self.statusText = LocalizedKey.roomScanCameraAccess.localized
                    print("❌ Camera access denied for RoomPlan")
                }
            }
        }
    }

    func stopSession() {
        captureView?.captureSession.stop()
        isScanning = false
        statusText = LocalizedKey.roomScanProcessing.localized
        stopLightMonitoring()
    }

    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        print("🧹 Cleaning up RoomPlan resources...")

        stopLightMonitoring()
        flashlightManager.turnOff()

        captureView?.delegate = nil
        captureView?.captureSession.stop()
        captureView = nil
        completion = nil

        isScanning = false
        statusText = LocalizedKey.roomScanReady.localized

        print("✅ RoomPlan cleanup complete")
    }

    private func startLightMonitoring() {
        guard autoFlashlightEnabled else { return }
        lightMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkAmbientLight()
        }
    }

    private func stopLightMonitoring() {
        lightMonitorTimer?.invalidate()
        lightMonitorTimer = nil
    }
    
    private func checkAmbientLight() {
        guard autoFlashlightEnabled, let device = captureDevice else {
            if !autoFlashlightEnabled, flashlightManager.isFlashlightOn { flashlightManager.turnOff() }
            return
        }
        let brightness = flashlightManager.calculateBrightness(
            iso: device.iso,
            exposureDuration: device.exposureDuration.seconds
        )
        flashlightManager.updateFlashlight(shouldAutoEnable: true, currentBrightness: brightness)
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    deinit {
        print("🗑️ RoomCaptureController deinitialized")
        cleanup()
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error = error {
            print("❌ Capture error: \(error.localizedDescription)")
            DispatchQueue.main.async { self.statusText = LocalizedKey.roomScanError.localized }
            return false
        }
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            print("❌ Processing error: \(error.localizedDescription)")
            DispatchQueue.main.async { self.statusText = LocalizedKey.roomScanProcessingError.localized }
            return
        }

        DispatchQueue.main.async {
            self.isScanning = false
            self.statusText = LocalizedKey.roomScanComplete.localized
            self.completion?(processedResult)
            self.stopLightMonitoring()
        }
    }
}
