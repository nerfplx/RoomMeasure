import SwiftUI
import SwiftData

struct RenameRoomSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @Binding var roomName: String
    let onSave: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectDetailNewName.localized)) {
                    TextField(LocalizedKey.projectRoomName.localized, text: $roomName)
                        .focused($isTextFieldFocused)
                }
            }
            .navigationTitle(LocalizedKey.projectDetailRename.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.commonDone.localized) {
                        onSave()
                        isPresented = false
                    }
                    .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isTextFieldFocused = true }
        }
        .presentationDetents([.height(200)])
    }
}
