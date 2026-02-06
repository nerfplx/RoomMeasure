import SwiftUI
import SwiftData

struct MeasurementEditSheet: View {
    @Environment(\.colorScheme) var colorScheme
    let measurement: SingleMeasurement
    let room: Room
    let modelContext: ModelContext
    @Binding var isPresented: Bool
    @State private var measurementName: String = ""
    @State private var notesText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectDetailInformation.localized)) {
                    TextField(LocalizedKey.projectRoomName.localized, text: $measurementName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.adaptivePrimaryText(for: colorScheme))
                    
                    HStack {
                        Text(LocalizedKey.saveDistance.localized)
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                        Spacer()
                        Text(UnitHelper.length(measurement.distance))
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    }
                    
                    HStack {
                        Text(LocalizedKey.projectCreated.localized)
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                        Spacer()
                        Text(measurement.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.adaptiveSecondaryText(for: colorScheme))
                    }
                }
                
                Section(header: Text(LocalizedKey.projectDetailNotesTitle.localized)) {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 150)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.commonSave.localized) {
                        let trimmedName = measurementName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty { measurement.name = trimmedName }
                        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
                        measurement.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                        try? modelContext.save()
                        isPresented = false
                    }
                    .disabled(measurementName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                measurementName = measurement.name
                notesText = measurement.notes ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }
}
