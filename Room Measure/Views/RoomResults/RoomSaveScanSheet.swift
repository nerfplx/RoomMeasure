import SwiftUI
import SwiftData
import RoomPlan

struct RoomSaveScanSheet: View {
    let capturedRoom: CapturedRoom
    let targetProject: MeasurementProject?
    let targetRoom: Room?
    let onSaved: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementProject.createdDate, order: .reverse)
    private var allProjects: [MeasurementProject]
    
    @State private var selectedProject: MeasurementProject?
    @State private var selectedRoom: Room?
    @State private var showNewProjectField = false
    @State private var newProjectName = ""
    @State private var showNewRoomField = false
    @State private var newRoomName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private var isQuickSave: Bool { targetProject != nil && targetRoom != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectDetail3DScan.localized)) {
                    if let dims = scanDimensions {
                        HStack {
                            Text(LocalizedKey.roomArea.localized).foregroundColor(.secondary)
                            Spacer()
                            Text(UnitHelper.area(dims.area))
                                .fontWeight(.semibold).foregroundColor(.orange)
                        }
                        HStack {
                            Text(LocalizedKey.roomHeight.localized).foregroundColor(.secondary)
                            Spacer()
                            Text(UnitHelper.length(dims.height))
                                .fontWeight(.semibold).foregroundColor(.orange)
                        }
                    }
                    HStack {
                        Text(LocalizedKey.roomLength.localized).foregroundColor(.secondary)
                        Spacer()
                        Text(UnitHelper.length(capturedRoom.walls.map(\.dimensions.x).reduce(0, +)))
                            .fontWeight(.semibold).foregroundColor(.orange)
                    }
                }
                
                if isQuickSave {
                    Section(header: Text(LocalizedKey.saveSelectProject.localized)) {
                        HStack {
                            Image(systemName: "folder.fill").foregroundColor(.blue)
                            Text(targetProject!.name).foregroundColor(.primary)
                        }
                        HStack {
                            Image(systemName: "house.fill").foregroundColor(.green)
                            Text(targetRoom!.name).foregroundColor(.primary)
                        }
                    }
                } else {
                    Section(header: Text(LocalizedKey.saveSelectProject.localized)) {
                        ForEach(allProjects) { project in
                            Button {
                                selectedProject = project
                                selectedRoom = nil
                                showNewRoomField = false
                                showNewProjectField = false
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill").foregroundColor(.blue)
                                    Text(project.name).foregroundColor(.primary)
                                    Spacer()
                                    if selectedProject?.id == project.id {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        Button {
                            showNewProjectField = true
                            selectedProject = nil
                            selectedRoom = nil
                            showNewRoomField = false
                            newProjectName = ""
                        } label: {
                            HStack {
                                Image(systemName: "folder.badge.plus").foregroundColor(.blue)
                                Text(LocalizedKey.projectsNew.localized).foregroundColor(.blue)
                            }
                        }
                        if showNewProjectField {
                            HStack {
                                TextField(LocalizedKey.projectsNamePlaceholder.localized, text: $newProjectName)
                                if !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Button { createProject() } label: {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let project = selectedProject {
                        Section(header: Text(LocalizedKey.saveSelectRoom.localized)) {
                            ForEach(project.rooms) { room in
                                Button {
                                    selectedRoom = room
                                    showNewRoomField = false
                                } label: {
                                    HStack {
                                        Image(systemName: "house.fill").foregroundColor(.green)
                                        Text(room.name).foregroundColor(.primary)
                                        Spacer()
                                        if selectedRoom?.id == room.id {
                                            Image(systemName: "checkmark").foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            Button {
                                showNewRoomField = true
                                selectedRoom = nil
                                newRoomName = ""
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill").foregroundColor(.orange)
                                    Text(LocalizedKey.saveCreateRoom.localized).foregroundColor(.orange)
                                }
                            }
                            if showNewRoomField {
                                TextField(LocalizedKey.projectSelectorRoomNamePlaceholder.localized,
                                          text: $newRoomName)
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizedKey.roomResultsSave.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(LocalizedKey.commonSave.localized) { save() }
                            .fontWeight(.semibold)
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear {
                if let p = targetProject {
                    selectedProject = p
                    selectedRoom = targetRoom
                }
            }
        }
        .presentationDetents(isQuickSave ? [.medium] : [.medium, .large])
    }
    
    private var scanDimensions: (area: Float, height: Float)? {
        guard let d = RoomDimensionsCalculator.calculate(from: capturedRoom) else { return nil }
        return (d.area, d.height)
    }
    
    private var canSave: Bool {
        if isQuickSave { return true }
        let projectOk = selectedProject != nil ||
        (showNewProjectField && !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
        guard projectOk else { return false }
        return selectedRoom != nil ||
        (showNewRoomField && !newRoomName.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    private func createProject() {
        let trimmed = newProjectName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let project = MeasurementProject(name: trimmed)
        modelContext.insert(project)
        try? modelContext.save()
        selectedProject = project
        selectedRoom = nil
        showNewProjectField = false
        newProjectName = ""
        showNewRoomField = true
        HapticManager.selection()
    }
    
    private func save() {
        let project: MeasurementProject
        if let p = isQuickSave ? targetProject : selectedProject {
            project = p
        } else if showNewProjectField {
            let trimmed = newProjectName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            let p = MeasurementProject(name: trimmed)
            modelContext.insert(p)
            project = p
        } else { return }
        
        let room: Room
        if let r = isQuickSave ? targetRoom : selectedRoom {
            room = r
        } else if showNewRoomField {
            let trimmed = newRoomName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            let r = Room(name: trimmed)
            project.rooms.append(r)
            room = r
        } else { return }
        
        isSaving = true
        
        Task {
            do {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("room_\(UUID().uuidString).usdz")
                try capturedRoom.export(to: url)
                let usdzData = try Data(contentsOf: url)
                try? FileManager.default.removeItem(at: url)
                
                let dims = RoomDimensionsCalculator.calculate(from: capturedRoom)
                
                await MainActor.run {
                    if let d = dims {
                        room.roomDimensions = RoomDimensions(
                            height:          d.height,
                            area:            d.area,
                            volume:          d.volume,
                            totalWallLength: capturedRoom.walls.map(\.dimensions.x).reduce(0, +),
                            wallCount:       capturedRoom.walls.count
                        )
                    }
                    room.usdzData    = usdzData
                    room.wallInfos   = capturedRoom.walls.map   { WallInfo(from: $0) }
                    room.doorInfos   = capturedRoom.doors.map   { DoorWindowInfo(from: $0, isDoor: true) }
                    room.windowInfos = capturedRoom.windows.map { DoorWindowInfo(from: $0, isDoor: false) }
                    
                    do {
                        try modelContext.save()
                        HapticManager.notification(.success)
                        isSaving = false
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                        isSaving = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
