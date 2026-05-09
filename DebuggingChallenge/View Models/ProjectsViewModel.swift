import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }

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
