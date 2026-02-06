import SwiftUI
import SwiftData

extension Room {
    func delete3DModel(context: ModelContext, haptic: Bool = true) {
        withAnimation {
            usdzData = nil
            roomDimensions = nil
            do {
                try context.save()
                if haptic { HapticManager.notification(.success) }
            } catch { print("❌ Error deleting 3D model: \(error)") }
        }
    }

    func deleteMeasurements(at offsets: IndexSet, context: ModelContext, haptic: Bool = true) {
        withAnimation {
            for index in offsets { measurements.remove(at: index) }
            do {
                try context.save()
                if haptic { HapticManager.notification(.success) }
            } catch { print("❌ Error deleting measurement: \(error)") }
        }
    }
}

extension Int {
    var formattedFileSize: String? {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB]
        f.countStyle = .file
        return f.string(fromByteCount: Int64(self))
    }
}
