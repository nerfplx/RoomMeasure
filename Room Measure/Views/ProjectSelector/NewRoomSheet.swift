import SwiftUI

struct NewRoomSheet: View {
    @Binding var isPresented: Bool
    @Binding var roomName: String
    let onCreate: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    private let roomSuggestions: [String] = [
        LocalizedKey.projectSelectorRoomLiving.localized,
        LocalizedKey.projectSelectorRoomKitchen.localized,
        LocalizedKey.projectSelectorRoomBedroom.localized,
        LocalizedKey.projectSelectorRoomBathroom.localized,
        LocalizedKey.projectSelectorRoomHallway.localized,
        LocalizedKey.projectSelectorRoomBalcony.localized
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedKey.projectSelectorRoomNameTitle.localized)) {
                    TextField(LocalizedKey.projectSelectorRoomNamePlaceholder.localized, text: $roomName)
                        .focused($isTextFieldFocused)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedKey.projectSelectorPopularNames.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(roomSuggestions, id: \.self) { suggestion in
                                Button {
                                    roomName = suggestion
                                } label: {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedKey.projectSelectorNewRoomTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedKey.commonCancel.localized) {
                        isPresented = false
                        roomName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKey.projectSelectorAddButton.localized) {
                        onCreate()
                        isPresented = false
                    }
                    .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { isTextFieldFocused = true }
        }
        .presentationDetents([.medium])
    }
}
