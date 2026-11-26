import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca, Ajustes y los plugins.
    @State private var config: AppConfig
    @State private var viewModel = BookListViewModel()
    @State private var selection: String? = "biblioteca"

    /// Los plugins se crean y se registran una sola vez, al arrancar la app.
    /// Es el único sitio del código que nombra cada plugin.
    init() {
        let config = AppConfig()
        // F3 Categorías: plugin común, se registra siempre (sin trait).
        PluginRegistry.shared.register(CategoryPlugin(config: config))
        // Las originales se registran aquí, cada una dentro de su trait:
        // #if Sagas
        // PluginRegistry.shared.register(SagaPlugin(config: config))
        // #endif
        _config = State(wrappedValue: config)
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
                // Las pantallas propias de los plugins activos.
                ForEach(PluginRegistry.shared.screens()) { screen in
                    NavigationStack {
                        screen.view
                    }
                    .tabItem { Label(screen.title, systemImage: screen.systemImage) }
                }
                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
            }
            .environment(config)
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
                        // Las pantallas propias de los plugins activos.
                        ForEach(PluginRegistry.shared.screens()) { screen in
                            NavigationLink(value: screen.tag) {
                                Label(screen.title, systemImage: screen.systemImage)
                            }
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
                    if let screen = PluginRegistry.shared.screen(tag: selection) {
                        NavigationStack {
                            screen.view
                        }
                    } else {
                        BookListView(viewModel: viewModel)
                    }
                }
            }
            .environment(config)
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
                    // Las pantallas propias de los plugins activos.
                    ForEach(PluginRegistry.shared.screens()) { screen in
                        NavigationLink(value: screen.tag) {
                            Label(screen.title, systemImage: screen.systemImage)
                        }
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
                    if let screen = PluginRegistry.shared.screen(tag: selection) {
                        NavigationStack {
                            screen.view
                        }
                    } else {
                        Text("Elige una opción")
                    }
                }
            }
            .environment(config)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1060, height: 740)
#endif
    }
}
