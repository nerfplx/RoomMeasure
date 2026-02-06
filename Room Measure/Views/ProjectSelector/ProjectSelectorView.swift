import SwiftUI
import SwiftData

struct ProjectSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementProject.createdDate, order: .reverse) private var projects: [MeasurementProject]
    
    let measurementType: MeasurementType
    
    @State private var selectedProject: MeasurementProject?
    @State private var selectedRoom: Room?
    @State private var showingNewProjectSheet = false
    @State private var showingNewRoomSheet = false
    @State private var newProjectName = ""
    @State private var newRoomName = ""
    @State private var proceedToMeasurement = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                measurementTypeHeader
                
                if projects.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            projectSelectionSection
                            
                            if selectedProject != nil {
                                roomSelectionSection
                            }
                        }
                        .padding()
                    }
                }
                
                bottomActionBar
            }
            .navigationTitle(LocalizedKey.projectSelectorTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.projectSelectorCancel.localized) {
                        if hapticFeedback { HapticManager.impact(.light) }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(
                    isPresented: $showingNewProjectSheet,
                    projectName: $newProjectName,
                    onCreate: createNewProject
                )
            }
            .sheet(isPresented: $showingNewRoomSheet) {
                NewRoomSheet(
                    isPresented: $showingNewRoomSheet,
                    roomName: $newRoomName,
                    onCreate: createNewRoom
                )
            }
            .fullScreenCover(isPresented: $proceedToMeasurement) {
                destinationView
            }
        }
    }
    
    private var measurementTypeHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: measurementType.icon)
                .font(.system(size: 40))
                .foregroundColor(measurementType.accentColor)
            
            Text(measurementType.selectorTitle)
                .font(.headline)
            
            Text(LocalizedKey.projectSelectorSelectProjectRoom.localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(LocalizedKey.projectSelectorNoProjects.localized)
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(LocalizedKey.projectSelectorCreateProjectMessage.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                if hapticFeedback { HapticManager.impact(.medium) }
                showingNewProjectSheet = true
            }) {
                Label(LocalizedKey.projectSelectorCreateProject.localized, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var projectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedKey.projectSelectorProject.localized)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    if hapticFeedback { HapticManager.impact(.light) }
                    showingNewProjectSheet = true
                }) {
                    Label(LocalizedKey.projectSelectorCreate.localized, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(projects) { project in
                ProjectSelectionCard(
                    project: project,
                    isSelected: selectedProject?.id == project.id,
                    onSelect: {
                        withAnimation(.spring(response: 0.3)) {
                            if hapticFeedback { HapticManager.selection() }
                            selectedProject = project
                            selectedRoom = nil
                        }
                    }
                )
            }
        }
    }
    
    private var roomSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Text(LocalizedKey.projectSelectorRoomRequired.localized)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("*")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    if hapticFeedback { HapticManager.impact(.light) }
                    showingNewRoomSheet = true
                }) {
                    Label(LocalizedKey.projectSelectorRoomAdd.localized, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 8)
            
            if let project = selectedProject {
                if project.rooms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "house")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(LocalizedKey.projectSelectorNoRooms.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedKey.projectSelectorCreateRoomContinue.localized)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                } else {
                    ForEach(project.rooms) { room in
                        RoomSelectionCard(
                            room: room,
                            isSelected: selectedRoom?.id == room.id,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    if hapticFeedback { HapticManager.selection() }
                                    selectedRoom = room
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if let project = selectedProject {
                        Text(project.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let room = selectedRoom {
                            Text("→ \(room.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text(LocalizedKey.projectSelectorSelectRoomFirst.localized)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text(LocalizedKey.projectSelectorNoProjects.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if hapticFeedback { HapticManager.notification(.success) }
                    proceedToMeasurement = true
                }) {
                    Text(LocalizedKey.projectSelectorProceed.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canProceed ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                }
                .disabled(!canProceed)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private var canProceed: Bool {
        selectedProject != nil && selectedRoom != nil
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if measurementType == .roomScan {
            RoomPlanScanView(targetProject: selectedProject, targetRoom: selectedRoom)
        } else {
            ARMeasurementView(targetProject: selectedProject, targetRoom: selectedRoom)
        }
    }
    
    private func createNewProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let project = MeasurementProject(name: newProjectName)
        modelContext.insert(project)
        
        do {
            try modelContext.save()
            selectedProject = project
            selectedRoom = nil
            newProjectName = ""
            if hapticFeedback { HapticManager.notification(.success) }
            print("✅ New project created: \(project.name)")
        } catch {
            print("❌ Error creating project: \(error)")
        }
    }
    
    private func createNewRoom() {
        guard let project = selectedProject,
              !newRoomName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let room = Room(name: newRoomName)
        project.rooms.append(room)
        
        do {
            try modelContext.save()
            selectedRoom = room
            newRoomName = ""
            if hapticFeedback { HapticManager.notification(.success) }
            print("✅ New room created: \(room.name)")
        } catch {
            print("❌ Error creating room: \(error)")
        }
    }
}

#Preview {
    ProjectSelectorView(measurementType: .roomScan)
        .modelContainer(for: MeasurementProject.self, inMemory: true)
}
