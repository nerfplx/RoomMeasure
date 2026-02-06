import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \MeasurementProject.createdDate, order: .reverse) private var projects: [MeasurementProject]
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var selectedProject: MeasurementProject? = nil
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppColors.adaptiveBackground(for: colorScheme)
                    .ignoresSafeArea()

                if projects.isEmpty {
                    emptyState
                } else {
                    projectsCard
                }
            }
            .navigationTitle(LocalizedKey.projectsTitle.localized)
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectSheet(
                    isPresented: $showingAddProject,
                    projectName: $newProjectName,
                    onSave: addProject
                )
            }
            .environment(\.locale, localizationManager.currentLocale)
        }
    }

    private var emptyState: some View {
        StyledEmptyState(
            icon: "folder.badge.plus",
            title: LocalizedKey.projectsEmpty.localized,
            description: LocalizedKey.projectsEmptyDescription.localized,
            actionTitle: LocalizedKey.projectsNew.localized,
            action: { showingAddProject = true }
        )
    }

    private var projectsCard: some View {
        VStack(spacing: 0) {
            List {
                ForEach(projects) { project in
                    ProjectListRow(project: project) {
                        selectedProject = project
                    } onDelete: {
                        deleteProject(project)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: min(listHeight, maxListHeight))
            .padding(.bottom, AppSpacing.xl)
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

    private var listHeight: CGFloat {
        let rowHeight: CGFloat = 82
        let spacing: CGFloat = AppSpacing.xs
        let count = CGFloat(projects.count)
        return count * rowHeight + max(0, count - 1) * spacing
    }

    private var maxListHeight: CGFloat {
        UIScreen.main.bounds.height * 0.70
    }

    private var addButton: some View {
        Button(action: { showingAddProject = true }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .offset(y: 24)
    }

    private func addProject() {
        withAnimation {
            let name = newProjectName.isEmpty ? LocalizedKey.projectsNew.localized : newProjectName
            modelContext.insert(MeasurementProject(name: name))
            newProjectName = ""
        }
    }

    private func deleteProject(_ project: MeasurementProject) {
        withAnimation {
            modelContext.delete(project)
            do {
                try modelContext.save()
                if hapticFeedback { HapticManager.notification(.success) }
            } catch {
                print("❌ Error deleting project: \(error)")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MeasurementProject.self, configurations: config)

    let p1 = MeasurementProject(name: "Квартира на Ленина 5")
    let p2 = MeasurementProject(name: "Офис — 3 этаж")
    let p3 = MeasurementProject(name: "Дача Подмосковье")
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)

    return ProjectsListView()
        .modelContainer(container)
}
