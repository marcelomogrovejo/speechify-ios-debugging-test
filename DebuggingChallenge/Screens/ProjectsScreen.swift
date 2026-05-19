import SwiftUI

struct ProjectsScreen: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @State private var searchText = ""
    @State private var loaderProgress: Float = 0.0
    // FIX: @ObservedObject -> @StateObject
    // This view is the sole owner of its viewModel (created fresh in MainScreen.body).
    // @ObservedObject could cause the VM to be recreated on parent re-renders, losing loaded data.
    @StateObject private var viewModel: ProjectsViewModel

    init(viewModel: ProjectsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            if viewModel.isLoading {
                Loader(progress: $loaderProgress, animated: true)
                    .frame(width: 64, height: 64)
            } else {
                List {
                    Section {
                        ForEach(filteredProjects) { project in
                            NavigationLink(value: project) {
                                ProjectRowView(project: project)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search Projects...")
                .navigationTitle("Projects")
                .navigationDestination(for: Project.self) { project in
                    ProjectDetailScreen(project: project)
                }
                .navigationDestination(for: WorkItem.self) { item in
                    WorkItemDetailView(item: item)
                }
            }
        }
        .onAppear { viewModel.loadProjects() }
    }

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return viewModel.projects
        } else {
            return viewModel.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
