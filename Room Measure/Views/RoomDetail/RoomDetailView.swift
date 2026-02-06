import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let project: MeasurementProject
    @Bindable var room: Room
    
    @State private var showingRenameSheet = false
    @State private var showingNotesSheet = false
    @State private var newRoomName = ""
    @State private var showRoomScan = false
    @State private var showARMeasurement = false
    @State private var showObjectMeasurement = false
    @State private var showObjectScan = false
    @State private var showRoom3D = false
    @State private var selectedMeasurement: SingleMeasurement?
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    private var scheme: ColorScheme {
        themeManager.currentTheme.colorScheme ?? colorScheme
    }
    
    var body: some View {
        ZStack {
            AppColors.adaptiveBackground(for: scheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if room.usdzData != nil || room.roomDimensions != nil {
                        scanDataSection
                        if !room.wallInfos.isEmpty {
                            floorPlanSection
                        }
                    }
                    if !room.measurements.isEmpty {
                        measurementsSection
                    }
                    notesSection
                    actionsSection
                }
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    newRoomName = room.name
                    showingRenameSheet = true
                }) {
                    Text(room.name)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(AppColors.adaptivePrimaryText(for: scheme))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(isPresented: $showRoom3D) {
            RoomResultsView(room: room)
        }
        
        .sheet(isPresented: $showRoomScan) {
            RoomPlanScanView(targetProject: project, targetRoom: room, showCloseButton: true, topPadding: 0)
        }
        .sheet(isPresented: $showARMeasurement) {
            ARMeasurementView(targetProject: project, targetRoom: room, showCloseButton: true, topPadding: 0)
        }
        .sheet(isPresented: $showObjectMeasurement) {
            ObjectMeasurementView(
                targetProject: project,
                targetRoom: room,
                showCloseButton: true,
                bottomInsetObject3D: AppSpacing.bottomInsetObject3D
            )
        }
        
        .sheet(isPresented: $showingRenameSheet) {
            RenameRoomSheet(
                isPresented: $showingRenameSheet,
                roomName: $newRoomName,
                onSave: {
                    room.name = newRoomName
                    try? modelContext.save()
                }
            )
        }
        .sheet(isPresented: $showingNotesSheet) {
            RoomNotesSheet(room: room, modelContext: modelContext, isPresented: $showingNotesSheet)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementEditSheet(
                measurement: measurement,
                room: room,
                modelContext: modelContext,
                isPresented: Binding(
                    get: { selectedMeasurement != nil },
                    set: { if !$0 { selectedMeasurement = nil } }
                )
            )
        }
    }
    
    private var scanDataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            StyledSectionHeader(LocalizedKey.projectDetail3DScan.localized, icon: "cube.fill")
                .padding(.horizontal, AppSpacing.xs)
            
            List {
                VStack(spacing: 0) {
                    if room.usdzData != nil {
                        Button(action: { showRoom3D = true }) {
                            Model3DRow(fileSize: room.usdzData!.count.formattedFileSize)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let dimensions = room.roomDimensions {
                        Divider().padding(.horizontal, AppSpacing.md)
                        RoomDimensionsCard(dimensions: dimensions)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        room.delete3DModel(context: modelContext, haptic: hapticFeedback)
                    } label: {
                        Label(LocalizedKey.commonDelete.localized, systemImage: "trash")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: scanSectionHeight)
            .scrollDisabled(true)
            .styledCard(colorScheme: scheme)
        }
    }
    
    private var scanSectionHeight: CGFloat {
        var h: CGFloat = 0
        if room.usdzData != nil       { h += 70  }
        if room.roomDimensions != nil { h += 230 }
        return h
    }
    
    private var floorPlanSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            StyledSectionHeader(LocalizedKey.floorPlanTitle.localized, icon: "map")
                .padding(.horizontal, AppSpacing.xs)
            
            VStack(alignment: .leading, spacing: 6) {
                FloorPlanView(
                    wallInfos:   room.wallInfos,
                    doorInfos:   room.doorInfos,
                    windowInfos: room.windowInfos
                )
                .frame(height: 220)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.adaptiveBorder(for: scheme), lineWidth: AppBorders.thin)
            )
            .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 6, x: 0, y: 3)
        }
    }
    
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            StyledSectionHeader(
                String(format: "\(LocalizedKey.roomMeasurements.localized) (%d)", room.measurements.count),
                icon: "ruler"
            )
            .padding(.horizontal, AppSpacing.xs)
            
            List {
                ForEach(room.measurements) { measurement in
                    Button(action: { selectedMeasurement = measurement }) {
                        InfoMeasurementRow(measurement: measurement)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let index = room.measurements.firstIndex(where: { $0.id == measurement.id }) {
                                room.deleteMeasurements(at: IndexSet(integer: index), context: modelContext, haptic: hapticFeedback)
                            }
                        } label: {
                            Label(LocalizedKey.commonDelete.localized, systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: CGFloat(room.measurements.count) * 80)
            .styledCard(colorScheme: scheme)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            StyledSectionHeader(LocalizedKey.projectDetailNotesTitle.localized, icon: "note.text")
                .padding(.horizontal, AppSpacing.xs)
            
            List {
                Button(action: { showingNotesSheet = true }) {
                    if let notes = room.notes, !notes.isEmpty {
                        NotesContentRow(notes: notes, createdAt: room.createdDate)
                    } else {
                        EmptyNotesRow()
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if let notes = room.notes, !notes.isEmpty {
                        Button(role: .destructive) {
                            withAnimation {
                                room.notes = nil
                                try? modelContext.save()
                                if hapticFeedback { HapticManager.notification(.success) }
                            }
                        } label: {
                            Label(LocalizedKey.commonDelete.localized, systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: (room.notes != nil && !room.notes!.isEmpty) ? 100 : 80)
            .scrollDisabled(true)
            .styledCard(colorScheme: scheme)
        }
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            StyledSectionHeader(LocalizedKey.projectDetailActions.localized, icon: "bolt.fill")
                .padding(.horizontal, AppSpacing.xs)
            
            VStack(spacing: AppSpacing.sm) {
                Button(action: { showRoomScan = true }) {
                    ActionRow(icon: "cube.transparent", iconColor: .blue,
                              title: LocalizedKey.projectDetailRescanRoom.localized)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showARMeasurement = true }) {
                    ActionRow(icon: "ruler", iconColor: .green,
                              title: LocalizedKey.roomAddMeasurement.localized)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showObjectMeasurement = true }) {
                    ActionRow(icon: "viewfinder.rectangular", iconColor: .purple,
                              title: LocalizedKey.measurementObjectScan.localized)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

private extension View {
    func styledCard(colorScheme: ColorScheme) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.adaptiveBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.adaptiveBorder(for: colorScheme), lineWidth: AppBorders.thin)
            )
            .shadow(color: AppColors.adaptiveShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }
}
