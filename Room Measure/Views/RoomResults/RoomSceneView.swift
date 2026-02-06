import SwiftUI
import SceneKit

struct RoomSceneView: UIViewRepresentable {
    let usdzURL: URL
    let wallInfos: [WallInfo]

    func makeUIView(context: Context) -> RoomSCNContainerView {
        let view = RoomSCNContainerView()
        view.setup(usdzURL: usdzURL, wallInfos: wallInfos)
        return view
    }

    func updateUIView(_ uiView: RoomSCNContainerView, context: Context) {}
}
