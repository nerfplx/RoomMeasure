import SwiftUI
import SwiftData
import AVFoundation

@main
struct RoomMeasureApp: App {
    @State private var hasRequestedCameraPermission = false
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        _ = LocalizationManager.shared
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MeasurementProject.self,
            WallInfo.self,
            DoorWindowInfo.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onAppear {
                    requestCameraPermissionIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func requestCameraPermissionIfNeeded() {
        guard !hasRequestedCameraPermission else { return }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    hasRequestedCameraPermission = true
                    if granted {
                        print("✅ Camera permission granted")
                    } else {
                        print("❌ Camera permission denied")
                    }
                }
            }
        case .authorized:
            hasRequestedCameraPermission = true
            print("✅ Camera already authorized")
        case .denied, .restricted:
            hasRequestedCameraPermission = true
            print("⚠️ Camera access denied or restricted")
        @unknown default:
            break
        }
    }
}
