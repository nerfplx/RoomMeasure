import SwiftUI
import RoomPlan
import SceneKit

struct Room3DView: View {
    let capturedRoom: CapturedRoom
    @State private var previewURL: URL?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text("room.results.loading.3d".localized)
                        .font(.headline).foregroundColor(.secondary)
                }
            } else if let error = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50)).foregroundColor(.red)
                    Text(LocalizedKey.commonError.localized).font(.headline)
                    Text(error).font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let url = previewURL {
                RoomSceneView(usdzURL: url, wallInfos: capturedRoom.walls.map { WallInfo(from: $0) })
                    .ignoresSafeArea()
            }
        }
        .onAppear { saveTemporaryUSDZ() }
        .onDisappear { cleanupTemporaryFile() }
    }

    private func saveTemporaryUSDZ() {
        isLoading = true
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("room_3d_\(UUID().uuidString).usdz")
        do {
            try capturedRoom.export(to: tempURL)
            previewURL = tempURL
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    private func cleanupTemporaryFile() {
        if let url = previewURL { try? FileManager.default.removeItem(at: url) }
    }
}
