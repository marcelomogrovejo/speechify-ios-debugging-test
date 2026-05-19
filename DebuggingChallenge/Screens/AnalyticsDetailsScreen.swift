import Charts
import SwiftUI

struct AnalyticsDetailsScreen: View {
    let details: AnalyticsDetails
    // FIX: @ObservedObject -> @StateObject
    // The VM is created inline in AnalyticsScreen's navigationDestination closure,
    // so this screen is the only owner. Without @StateObject, SwiftUI might replace
    // the VM on re-evaluation, losing any loaded recent projects.
    @StateObject var viewModel: AnalyticsDetailsViewModel
    @State private var loaderProgress: Float = 0.0

    init(details: AnalyticsDetails, viewModel: AnalyticsDetailsViewModel) {
        self.details = details
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Text("\(details.value)")
                        .font(.system(size: 48, weight: .bold))
                    Text(details.trend)
                        .font(.headline)
                        .foregroundColor(details.trend.contains("↑") ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            Section("Details") {
                LabeledContent("Period", value: details.period)
                LabeledContent("Last Updated", value: "2 hours ago")
            }

            Chart {
                LineMark(
                    x: .value("Week", "W1"),
                    y: .value("Value", 35)
                )
                LineMark(
                    x: .value("Week", "W2"),
                    y: .value("Value", 39)
                )
                LineMark(
                    x: .value("Week", "W3"),
                    y: .value("Value", 42)
                )
            }
            .frame(height: 200)

            Section("Recent Projects") {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        Loader(progress: $loaderProgress, animated: true)
                            .frame(width: 64, height: 64)
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.recentProjects) { project in
                        NavigationLink(value: project) {
                            Text(project.name)
                        }
                    }
                }
            }
        }
        .navigationTitle(details.title)
        .onAppear { viewModel.loadRecentProjects() }
    }
}
