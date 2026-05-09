import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }

    func loadProjects() {
        Task {
            isLoading = true
            let fetchedProjects = await projectService.fetchProjects()
            projects = fetchedProjects
            isLoading = false
        }
    }
}
