import SwiftUI
import SwiftData

struct RoomNotesSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Bindable var room: Room
    let modelContext: ModelContext
    @Binding var isPresented: Bool
    @State private var notesText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectDetailRoomNotes.localized)) {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 150)
                        .focused($isTextFieldFocused)
                }
            }
            .navigationTitle(LocalizedKey.projectDetailNotesTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.commonSave.localized) {
                        let trimmed = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
                        room.notes = trimmed.isEmpty ? nil : notesText
                        if !trimmed.isEmpty { room.createdDate = Date() }
                        try? modelContext.save()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                notesText = room.notes ?? ""
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }
}
