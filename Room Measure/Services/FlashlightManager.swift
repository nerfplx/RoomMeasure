import AVFoundation
import UIKit

class FlashlightManager: ObservableObject {
    static let shared = FlashlightManager()
    
    @Published var isFlashlightOn = false
    @Published var currentBrightness: Float = 1.0
    
    private var device: AVCaptureDevice?
    private var brightnessThreshold: Float = 0.3
    
    private init() {
        setupDevice()
    }
    
    private func setupDevice() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("❌ Flashlight: Camera device not available")
            return
        }
        self.device = device
    }
    
    func updateFlashlight(shouldAutoEnable: Bool, currentBrightness: Float) {
        guard shouldAutoEnable else {
            turnOff()
            return
        }
        
        self.currentBrightness = currentBrightness
        
        if currentBrightness < brightnessThreshold {
            turnOn()
        } else {
            turnOff()
        }
    }
    
    func turnOn() {
        guard let device = device, device.hasTorch else {
            print("❌ Flashlight: Device doesn't have torch")
            return
        }
        
        guard !isFlashlightOn else { return }
        
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: 1.0)
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.isFlashlightOn = true
            }
            print("💡 Flashlight turned ON")
        } catch {
            print("❌ Flashlight error: \(error.localizedDescription)")
        }
    }
    
    func turnOff() {
        guard let device = device, device.hasTorch else { return }
        guard isFlashlightOn else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.isFlashlightOn = false
            }
            print("💡 Flashlight turned OFF")
        } catch {
            print("❌ Flashlight error: \(error.localizedDescription)")
        }
    }
    
    deinit {
        turnOff()
    }
}

extension FlashlightManager {
    
    func calculateBrightness(iso: Float, exposureDuration: Double) -> Float {
        let normalizedISO = min(max((iso - 50) / 3150, 0), 1)
        
        let normalizedExposure = Float(min(max(exposureDuration * 100, 0), 1))
        
        let brightness = 1.0 - ((normalizedISO + normalizedExposure) / 2.0)
        
        return max(min(brightness, 1.0), 0.0)
    }
}
