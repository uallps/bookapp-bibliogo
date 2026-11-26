import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca y Ajustes.
    @State private var config = AppConfig()
    @State private var viewModel = BookListViewModel()
    @State private var selection: String? = "biblioteca"
    /// F3 Categorías: plugin común, se crea y se registra siempre (sin trait).
    @State private var categories: CategoryPlugin

    /// Los plugins se crean y se registran una sola vez, al arrancar la app.
    init() {
        let categories = CategoryPlugin()
        PluginRegistry.shared.register(categories)
        _categories = State(wrappedValue: categories)
    }

    var body: some Scene {
        WindowGroup {
#if os(iOS)
            TabView {
                BookListView(viewModel: viewModel)
                    .tabItem { Label("Biblioteca", systemImage: "books.vertical.fill") }
                NavigationStack {
                    StatisticsView(statistics: viewModel.statistics)
                }
                .tabItem { Label("Hábitos", systemImage: "leaf.fill") }
                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
            }
            .environment(config)
            .environment(categories)
            .tint(Color.bookAccent)
#elseif os(macOS)
            NavigationSplitView {
                List(selection: $selection) {
                    Section {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.bookAccent)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("BiblioGo")
                                    .font(.system(.headline, design: .serif))
                                Text("Espacio sereno")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section("Explorar") {
                        NavigationLink(value: "biblioteca") {
                            Label("Biblioteca", systemImage: "books.vertical.fill")
                        }
                        NavigationLink(value: "estadisticas") {
                            Label("Hábitos", systemImage: "leaf.fill")
                        }
                        NavigationLink(value: "ajustes") {
                            Label("Ajustes", systemImage: "slider.horizontal.3")
                        }
                    }
                }
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 270)
            } detail: {
                switch selection {
                case "biblioteca":
                    BookListView(viewModel: viewModel)
                case "estadisticas":
                    NavigationStack {
                        StatisticsView(statistics: viewModel.statistics)
                    }
                case "ajustes":
                    NavigationStack {
                        SettingsView()
                    }
                default:
                    BookListView(viewModel: viewModel)
                }
            }
            .environment(config)
            .environment(categories)
            .tint(Color.bookAccent)
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
            .environment(categories)
            .tint(Color.bookAccent)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1060, height: 740)
#endif
    }
}
