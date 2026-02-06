import SwiftUI
import RoomPlan
import SwiftData
import QuickLook

struct RoomResultsView: View {
    let source: RoomSource
    let targetProject: MeasurementProject?
    let targetRoom: Room?
    let onDismiss: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var previewURL: URL?
    @State private var isLoadingUSDZ = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var exportError: String?
    @State private var showingExportError = false
    @State private var showingSaveScanSheet = false
    @State private var showingARPreview = false
    @State private var isPreparingAR = false
    
    private let planSectionHeight: CGFloat = 324
    
    var body: some View {
        let content = GeometryReader { geo in
            VStack(spacing: 0) {
                sceneView
                    .frame(height: max(100, geo.size.height - planSectionHeight))
                bottomSection
                    .frame(height: planSectionHeight)
            }
        }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(isLive ? LocalizedKey.roomResultsTitle.localized : LocalizedKey.projectDetail3DModel.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL { ShareSheet(items: [url]) }
            }
            .sheet(isPresented: $showingSaveScanSheet) {
                if case .live(let capturedRoom) = source {
                    RoomSaveScanSheet(
                        capturedRoom: capturedRoom,
                        targetProject: targetProject,
                        targetRoom: targetRoom,
                        onSaved: {
                            showingSaveScanSheet = false
                            onDismiss?()
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingARPreview) {
                if let url = arPreviewURL {
                    ARQuickLookSheet(usdzURL: url)
                        .ignoresSafeArea()
                }
            }
            .alert("room.results.export.error".localized, isPresented: $showingExportError) {
                Button(LocalizedKey.commonOK.localized) { showingExportError = false }
            } message: {
                if let msg = exportError { Text(msg) }
            }
            .onAppear   { setupSavedPreview() }
            .onDisappear { cleanupPreview() }
            .overlay {
                if isPreparingAR {
                    ZStack {
                        Color.black.opacity(0.55).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.4)
                            Text("Подготовка AR...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(28)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        
        if isLive {
            return AnyView(NavigationStack { content })
        } else {
            return AnyView(content.toolbar(.hidden, for: .tabBar))
        }
    }
    
    @ViewBuilder
    private var sceneView: some View {
        ZStack {
            switch source {
            case .live(let cr):
                Room3DView(capturedRoom: cr)
            case .saved(_, let walls, _, _, _):
                if let url = previewURL {
                    RoomSceneView(usdzURL: url, wallInfos: walls)
                } else if isLoadingUSDZ {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white)
                        Text(LocalizedKey.projectDetailLoading3D.localized)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50)).foregroundColor(.orange)
                        Text(LocalizedKey.projectDetailLoadingError.localized)
                            .font(.headline).foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var bottomSection: some View {
        VStack {
            FloorPlanView(wallInfos: wallInfos, doorInfos: doorInfos, windowInfos: windowInfos)
                .frame(height: 220)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }
        
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isLive {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedKey.commonClose.localized) { onDismiss?() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showingSaveScanSheet = true }) {
                        Text(LocalizedKey.roomResultsSave.localized).fontWeight(.semibold)
                    }
                    
                    Menu {
                        Button(action: exportPDFAndShare) {
                            Label(LocalizedKey.projectExportPDF.localized, systemImage: "doc.fill")
                        }
                        Button(action: exportLiveUSDZ) {
                            Label(LocalizedKey.roomResultsExport3D.localized, systemImage: "cube.fill")
                        }
                        Divider()
                        Button(action: exportLiveUSDZForAR) {
                            Label(LocalizedKey.ARView.localized, systemImage: "arkit")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } else {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: exportPDFAndShare) {
                        Label(LocalizedKey.projectExportPDF.localized, systemImage: "doc.fill")
                    }
                    Button(action: exportSavedUSDZ) {
                        Label(LocalizedKey.roomResultsExport3D.localized, systemImage: "cube.fill")
                    }
                    if previewURL != nil {
                        Divider()
                        Button(action: {
                            isPreparingAR = true
                            Task {
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                await MainActor.run {
                                    isPreparingAR = false
                                    showingARPreview = true
                                }
                            }
                        })
                        {
                            Label(LocalizedKey.ARView.localized, systemImage: "arkit")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

private extension RoomResultsView {
    var arPreviewURL: URL? { previewURL }
}

extension RoomResultsView {
    init(capturedRoom: CapturedRoom, targetProject: MeasurementProject?, targetRoom: Room?, onDismiss: @escaping () -> Void) {
        self.source        = .live(capturedRoom)
        self.targetProject = targetProject
        self.targetRoom    = targetRoom
        self.onDismiss     = onDismiss
    }
    
    init(room: Room) {
        self.source = .saved(
            usdzData:    room.usdzData ?? Data(),
            wallInfos:   room.wallInfos,
            doorInfos:   room.doorInfos,
            windowInfos: room.windowInfos,
            dimensions:  room.roomDimensions
        )
        self.targetProject = nil
        self.targetRoom    = nil
        self.onDismiss     = nil
    }
}

private extension RoomResultsView {
    var scheme: ColorScheme { themeManager.currentTheme.colorScheme ?? colorScheme }
    var isLive: Bool { if case .live = source { return true }; return false }
    
    var wallInfos: [WallInfo] {
        switch source {
        case .live(let cr): return cr.walls.map { WallInfo(from: $0) }
        case .saved(_, let w, _, _, _): return w
        }
    }
    var doorInfos: [DoorWindowInfo] {
        switch source {
        case .live(let cr): return cr.doors.map { DoorWindowInfo(from: $0, isDoor: true) }
        case .saved(_, _, let d, _, _): return d
        }
    }
    var windowInfos: [DoorWindowInfo] {
        switch source {
        case .live(let cr): return cr.windows.map { DoorWindowInfo(from: $0, isDoor: false) }
        case .saved(_, _, _, let w, _): return w
        }
    }
    var dimDisplay: (height: Float, area: Float)? {
        switch source {
        case .live(let cr):
            guard let d = RoomDimensionsCalculator.calculate(from: cr) else { return nil }
            return (d.height, d.area)
        case .saved(_, _, _, _, let dims):
            guard let dims else { return nil }
            return (dims.height, dims.area)
        }
    }
}

private extension RoomResultsView {
    func setupSavedPreview() {
        guard case .saved(let data, _, _, _, _) = source, !data.isEmpty else { return }
        isLoadingUSDZ = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("preview_\(UUID().uuidString).usdz")
            try? data.write(to: url)
            DispatchQueue.main.async { previewURL = url; isLoadingUSDZ = false }
        }
    }
    
    func cleanupPreview() {
        if let url = previewURL { try? FileManager.default.removeItem(at: url) }
    }
}

private extension RoomResultsView {
    func timestamp() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HH-mm"; return f.string(from: Date())
    }
    
    func exportPDFAndShare() {
        let capturedRoom: CapturedRoom? = {
            if case .live(let cr) = source { return cr }
            return nil
        }()
        let measurements: [SingleMeasurement] = targetRoom?.measurements ?? []
        let data = RoomPDFExporter.generate(
            wallInfos:    wallInfos,
            doorInfos:    doorInfos,
            windowInfos:  windowInfos,
            dimDisplay:   dimDisplay,
            capturedRoom: capturedRoom,
            measurements: measurements
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("RoomScan_\(timestamp()).pdf")
        do { try data.write(to: url); shareURL = url; showingShareSheet = true }
        catch { exportError = error.localizedDescription; showingExportError = true }
    }
    
    func exportLiveUSDZForAR() {
        guard case .live(let capturedRoom) = source else { return }
        isPreparingAR = true
        Task {
            do {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ar_live_\(UUID().uuidString).usdz")
                try capturedRoom.export(to: url)
                await MainActor.run {
                    previewURL = url
                    isPreparingAR = false
                    showingARPreview = true
                }
            } catch {
                await MainActor.run {
                    isPreparingAR = false
                    exportError = error.localizedDescription
                    showingExportError = true
                }
            }
        }
    }
    
    func exportLiveUSDZ() {
        guard case .live(let capturedRoom) = source else { return }
        Task {
            do {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("room_\(UUID().uuidString).usdz")
                try capturedRoom.export(to: url)
                let exportURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("Room_\(timestamp()).usdz")
                try FileManager.default.copyItem(at: url, to: exportURL)
                try? FileManager.default.removeItem(at: url)
                await MainActor.run { shareURL = exportURL; showingShareSheet = true }
            } catch {
                await MainActor.run { exportError = error.localizedDescription; showingExportError = true }
            }
        }
    }
    
    func exportSavedUSDZ() {
        guard case .saved(let data, _, _, _, _) = source, !data.isEmpty else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Room_\(timestamp()).usdz")
        do { try data.write(to: url); shareURL = url; showingShareSheet = true }
        catch { exportError = error.localizedDescription; showingExportError = true }
    }
}

#Preview { Text("RoomResultsView") }
