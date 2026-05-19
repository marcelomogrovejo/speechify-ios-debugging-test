import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var analyticsDetails: [AnalyticsDetails] = []
    @Published var recentProjects: [Project] = []
    @Published var isLoading: Bool = false
    let analyticsService: AnalyticsService
    let projectService: ProjectService

    init(analyticsService: AnalyticsService, projectService: ProjectService) {
        self.analyticsService = analyticsService
        self.projectService = projectService
    }

    // FIX: @MainActor ensures @Published properties update on the main thread (same as ProjectsViewModel).
    @MainActor
    func loadAnalytics() {
        defer { isLoading = false }
        isLoading = true
        Task {
            let details = await analyticsService.fetchAnalyticsDetails()
            let projects = await projectService.fetchProjects()
            analyticsDetails = details
            recentProjects = projects
        }
    }
}
