import SwiftUI

struct NewProjectSheet: View {
    @Binding var isPresented: Bool
    @Binding var projectName: String
    let onCreate: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectSelectorProjectInfo.localized)) {
                    TextField(LocalizedKey.projectSelectorProjectNamePlaceholder.localized, text: $projectName)
                        .focused($isTextFieldFocused)
                }

                Section {
                    Text(LocalizedKey.projectDetailCanAddLater.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedKey.projectSelectorNewProjectTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) {
                        isPresented = false
                        projectName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.projectSelectorCreate.localized) {
                        onCreate()
                        isPresented = false
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { isTextFieldFocused = true }
        }
        .presentationDetents([.medium])
    }
}
