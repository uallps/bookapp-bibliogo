import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca y Ajustes.
    @State private var config = AppConfig()
    @State private var viewModel = BookListViewModel()
    @State private var selection: String? = "biblioteca"

    var body: some Scene {
        WindowGroup {
#if os(iOS)
            TabView {
                BookListView(viewModel: viewModel)
                    .tabItem { Label("Biblioteca", systemImage: "books.vertical") }
                NavigationStack {
                    StatisticsView(statistics: viewModel.statistics)
                }
                .tabItem { Label("Estadísticas", systemImage: "checklist") }
                SettingsView()
                    .tabItem { Label("Ajustes", systemImage: "gearshape") }
            }
            .environment(config)
#else
            NavigationSplitView {
                List(selection: $selection) {
                    NavigationLink(value: "biblioteca") {
                        Label("Biblioteca", systemImage: "books.vertical")
                    }
                    NavigationLink(value: "estadisticas") {
                        Label("Estadísticas", systemImage: "checklist")
                    }
                    NavigationLink(value: "ajustes") {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            } detail: {
                switch selection {
                case "biblioteca":
                    BookListView(viewModel: viewModel)
                case "estadisticas":
                    NavigationStack {
                        StatisticsView(statistics: viewModel.statistics)
                    }
                case "ajustes":
                    SettingsView()
                default:
                    Text("Elige una opción")
                }
            }
            .environment(config)
#endif
        }
    }
}
