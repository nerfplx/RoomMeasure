import SwiftUI
import SwiftData
import UIKit

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var project: MeasurementProject
    @State private var showingExportOptions = false
    @State private var showingRenameSheet = false
    @State private var showingAddRoomSheet = false
    @State private var newProjectName = ""
    @State private var newRoomName = ""
    @State private var pdfToShare: URL?
    @State private var showingShareSheet = false
    @State private var selectedRoom: Room? = nil

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.adaptiveBackground(for: colorScheme)
                .ignoresSafeArea()
            
                VStack {
                    if project.rooms.isEmpty {
                        emptyState
                    } else {
                        roomsCard
                    }
                }
                .padding(.horizontal, AppSpacing.md)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRoom) { room in
            RoomDetailView(project: project, room: room)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    newProjectName = project.name
                    showingRenameSheet = true
                }) {
                    Text(project.name)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingExportOptions = true }) {
                        Label(LocalizedKey.projectDetailExport.localized, systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3).foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameProjectSheet(
                isPresented: $showingRenameSheet,
                projectName: $newProjectName,
                onSave: {
                    project.name = newProjectName
                    try? modelContext.save()
                }
            )
            .onAppear { newProjectName = project.name }
        }
        .sheet(isPresented: $showingAddRoomSheet) {
            NewRoomSheet(
                isPresented: $showingAddRoomSheet,
                roomName: $newRoomName,
                onCreate: createNewRoom
            )
        }
        .confirmationDialog(LocalizedKey.projectDetailExport.localized, isPresented: $showingExportOptions) {
            Button(LocalizedKey.projectExportPDF.localized) { exportToPDF() }
            Button(LocalizedKey.commonCancel.localized, role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL = pdfToShare {
                ShareSheet(items: [pdfURL])
                    .onDisappear { pdfToShare = nil }
            }
        }
    }

    private var emptyState: some View {
        StyledEmptyState(
            icon: "house.badge.exclamationmark",
            title: LocalizedKey.projectDetailNoRooms.localized,
            description: LocalizedKey.projectDetailNoRoomsDescription.localized,
            actionTitle: LocalizedKey.projectAddRoom.localized,
            action: { showingAddRoomSheet = true }
        )
    }

    private var roomsCard: some View {
        VStack(spacing: 0) {
            List {
                ForEach(project.rooms) { room in
                    RoomListRow(room: room) {
                        selectedRoom = room
                    } onDelete: {
                        if let index = project.rooms.firstIndex(where: { $0.id == room.id }) {
                            deleteRooms(offsets: IndexSet(integer: index))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: min(roomsListHeight, maxListHeight))
            .scrollDisabled(roomsListHeight <= maxListHeight)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.adaptiveBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.thin)
        )
        .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 6, x: 0, y: 3)
        .overlay(alignment: .bottom) { addButton }
        .padding(.top, AppSpacing.lg)
    }

    private var roomsListHeight: CGFloat {
        let rowHeight: CGFloat = 82
        let spacing: CGFloat = AppSpacing.xs
        let count = CGFloat(project.rooms.count)
        return count * rowHeight + max(0, count - 1) * spacing
    }

    private var maxListHeight: CGFloat {
        UIScreen.main.bounds.height * 0.7
    }

    private var addButton: some View {
        Button(action: { showingAddRoomSheet = true }) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .offset(y: 24)
    }

    private func createNewRoom() {
        guard !newRoomName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let room = Room(name: newRoomName)
        project.rooms.append(room)
        do {
            try modelContext.save()
            newRoomName = ""
        } catch {
            print("❌ Error creating room: \(error)")
        }
    }

    private func deleteRooms(offsets: IndexSet) {
        withAnimation {
            for index in offsets { project.rooms.remove(at: index) }
            try? modelContext.save()
        }
    }

    private func exportToPDF() {
        let pdfData = ProjectPDFExporter.generate(for: project)
        let fileName = "\(project.name.replacingOccurrences(of: " ", with: "_"))_\(ProjectPDFExporter.timestamp()).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: fileURL)
            pdfToShare = fileURL
            showingShareSheet = true
        } catch {
            print("❌ Error saving PDF: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MeasurementProject.self, configurations: config)

        let project = MeasurementProject(name: "Квартира на Ленина 5")

        let r1 = Room(name: "Гостиная")
        r1.roomDimensions = RoomDimensions(height: 2.7, area: 24.5, volume: 66.15, totalWallLength: 20.0, wallCount: 4)

        let r2 = Room(name: "Спальня")
        r2.roomDimensions = RoomDimensions(height: 2.7, area: 18.0, volume: 48.6, totalWallLength: 17.2, wallCount: 4)

        let r3 = Room(name: "Кухня")
        r3.measurements.append(SingleMeasurement(name: "Ширина столешницы", distance: 0.6))
        r3.measurements.append(SingleMeasurement(name: "Высота потолка", distance: 2.7))

        project.rooms.append(contentsOf: [r1, r2, r3])
        container.mainContext.insert(project)

        return ProjectDetailView(project: project)
            .modelContainer(container)
    }
}
