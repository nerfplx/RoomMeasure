import SwiftUI
import RoomPlan


struct FloorPlanView: View {
    let wallInfos:   [WallInfo]
    let doorInfos:   [DoorWindowInfo]
    let windowInfos: [DoorWindowInfo]

    @State private var planImage: UIImage?

    init(capturedRoom: CapturedRoom) {
        self.wallInfos   = capturedRoom.walls.map   { WallInfo(from: $0) }
        self.doorInfos   = capturedRoom.doors.map   { DoorWindowInfo(from: $0, isDoor: true)  }
        self.windowInfos = capturedRoom.windows.map { DoorWindowInfo(from: $0, isDoor: false) }
    }

    init(wallInfos: [WallInfo], doorInfos: [DoorWindowInfo], windowInfos: [DoorWindowInfo]) {
        self.wallInfos   = wallInfos
        self.doorInfos   = doorInfos
        self.windowInfos = windowInfos
    }

    var body: some View {
        ZStack {
            Color.white.cornerRadius(12)

            if let image = planImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .contextMenu {
                        Button { shareImage() } label: {
                            Label(LocalizedKey.commonShare.localized, systemImage: "square.and.arrow.up")
                        }
                    }
            } else {
                ProgressView().tint(.gray)
            }
        }
        .onAppear { render() }
        .onChange(of: wallInfos.count) { _, _ in render() }
    }

    private func render() {
        let screenW = UIScreen.main.bounds.width
        let size = CGSize(width: screenW - 32, height: 240)
        DispatchQueue.global(qos: .userInitiated).async {
            let img = FloorPlanRenderer.render(
                wallInfos: wallInfos, doorInfos: doorInfos, windowInfos: windowInfos,
                size: size, isExport: true
            )
            DispatchQueue.main.async { planImage = img }
        }
    }

    private func shareImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let img = FloorPlanRenderer.render(
                wallInfos: wallInfos, doorInfos: doorInfos, windowInfos: windowInfos,
                size: CGSize(width: 1200, height: 900), isExport: true
            )
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root  = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
            }
        }
    }
}

extension FloorPlanRenderer {
    static func renderHighRes(wallInfos: [WallInfo], doorInfos: [DoorWindowInfo], windowInfos: [DoorWindowInfo]) -> UIImage {
        render(wallInfos: wallInfos, doorInfos: doorInfos, windowInfos: windowInfos,
               size: CGSize(width: 1200, height: 900), isExport: true)
    }
}
