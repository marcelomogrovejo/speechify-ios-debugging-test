import Combine

class AnalyticsDetailsViewModel: ObservableObject {
    @Published var recentProjects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }

    // FIX: @MainActor ensures @Published properties update on the main thread (same as the other VMs).
    @MainActor
    func loadRecentProjects() {
        defer { isLoading = false }
        isLoading = true
        Task {
            let projects = await projectService.fetchProjects()
            recentProjects = projects
        }
    }
}
