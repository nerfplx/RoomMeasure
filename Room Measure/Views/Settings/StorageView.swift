import SwiftUI
import SwiftData

struct StorageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [MeasurementProject]
    @State private var showingClearAlert = false
    @State private var storageSize: String = LocalizedKey.storageCalculating.localized

    var body: some View {
        List {
            Section(header: Text(LocalizedKey.storageUsage.localized)) {
                HStack {
                    Text(LocalizedKey.storageProjects.localized)
                    Spacer()
                    Text("\(projects.count)").foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedKey.storageMeasurements.localized)
                    Spacer()
                    Text("\(totalMeasurements)").foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedKey.storageSize.localized)
                    Spacer()
                    Text(storageSize).foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(LocalizedKey.storageClearAll.localized)
                    }
                }
                .disabled(projects.isEmpty)
            }
        }
        .navigationTitle(LocalizedKey.storageTitle.localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: calculateStorageSize)
        .alert(LocalizedKey.storageClearConfirm.localized, isPresented: $showingClearAlert) {
            Button(LocalizedKey.commonCancel.localized, role: .cancel) {}
            Button(LocalizedKey.commonDelete.localized, role: .destructive, action: clearAllData)
        } message: {
            Text(LocalizedKey.storageClearMessage.localized)
        }
    }

    private var totalMeasurements: Int {
        projects.reduce(0) { $0 + $1.totalMeasurements }
    }

    private func calculateStorageSize() {
        var bytes = 0
        for project in projects {
            for room in project.rooms {
                bytes += room.usdzData?.count ?? 0
                bytes += room.measurements.count * 256
                bytes += room.wallInfos.count * 128
            }
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        storageSize = formatter.string(fromByteCount: Int64(bytes))
    }

    private func clearAllData() {
        for project in projects { modelContext.delete(project) }
        do {
            try modelContext.save()
            calculateStorageSize()
            print("✅ All data cleared")
        } catch {
            print("❌ Error clearing data: \(error)")
        }
    }
}
