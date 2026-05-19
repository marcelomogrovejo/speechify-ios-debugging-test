import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }

    // FIX: Added @MainActor to ensure @Published properties are updated on the main thread.
    // Without this, the Task could resume on a background thread after the await,
    // causing "Publishing changes from background threads" warnings and potential UI glitches.
    @MainActor
    func loadProjects() {
        defer { isLoading = false }
        isLoading = true
        Task {
            let fetchedProjects = await projectService.fetchProjects()
            projects = fetchedProjects
        }
    }
}
