import SwiftUI
import SwiftData

struct SaveMeasurementSheet: View {
    let distance: Float
    let targetProject: MeasurementProject?  
    let targetRoom: Room?
    let modelContext: ModelContext
    let onSaved: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MeasurementProject.createdDate, order: .reverse)
    private var allProjects: [MeasurementProject]
    @AppStorage("measurementUnit") private var measurementUnit = "metric"

    @State private var measurementName = ""
    @State private var measurementNotes = ""
    @State private var selectedProject: MeasurementProject?
    @State private var selectedRoom: Room?
    @State private var showNewProjectField = false
    @State private var newProjectName = ""
    @State private var showNewRoomField = false
    @State private var newRoomName = ""
    @FocusState private var nameFieldFocused: Bool

    private var isQuickSave: Bool { targetProject != nil && targetRoom != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.arResult.localized)) {
                    HStack {
                        Text(LocalizedKey.saveDistance.localized).foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDistance)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text(LocalizedKey.arDetails.localized)) {
                    TextField(LocalizedKey.saveNamePlaceholder.localized, text: $measurementName)
                        .focused($nameFieldFocused)
                    TextField(LocalizedKey.saveNotesPlaceholder.localized, text: $measurementNotes, axis: .vertical)
                        .lineLimit(2...4)
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
                                showNewProjectField = false
                                showNewRoomField = false
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
                                TextField(LocalizedKey.projectSelectorRoomNamePlaceholder.localized, text: $newRoomName)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedKey.saveMeasurementTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.commonSave.localized) { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                nameFieldFocused = true
                if let p = targetProject {
                    selectedProject = p
                    selectedRoom = targetRoom
                }
            }
        }
        .presentationDetents(isQuickSave ? [.medium] : [.medium, .large])
    }

    private var formattedDistance: String {
        UnitHelper.lengthFull(distance)
    }

    private var canSave: Bool {
        guard !measurementName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
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

        let name  = measurementName.trimmingCharacters(in: .whitespaces)
        let notes = measurementNotes.trimmingCharacters(in: .whitespaces)
        room.measurements.append(SingleMeasurement(
            name: name,
            distance: distance,
            notes: notes.isEmpty ? nil : notes
        ))

        try? modelContext.save()
        HapticManager.notification(.success)
        onSaved()
    }
}
