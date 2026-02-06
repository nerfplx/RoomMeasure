import SwiftUI
import RoomPlan

struct RoomCaptureViewRepresentable: UIViewRepresentable {
    @ObservedObject var roomCaptureController: RoomCaptureController
    let onCaptureComplete: (CapturedRoom) -> Void

    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        roomCaptureController.setupCaptureView(captureView, completion: onCaptureComplete)
        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: ()) {
        uiView.delegate = nil
    }
}
