import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca, Ajustes y los plugins.
    @State private var config: AppConfig
    @State private var viewModel: BookListViewModel
    @State private var selection: String? = "biblioteca"
#if Portadas
    /// O7 Foto de la portada: plugin opcional activado con el trait `Portadas`.
    @State private var covers: BookCoversPlugin
#endif

    /// Los plugins se crean y se registran una sola vez, al arrancar la app.
    /// Es el único sitio del código que nombra cada plugin.
    init() {
        let config = AppConfig()
        // La biblioteca: los plugins que necesitan los libros (o cambiarlos) la reciben al crearse.
        let viewModel = BookListViewModel()
        // F3 Categorías: plugin común, se registra siempre (sin trait).
        PluginRegistry.shared.register(CategoryPlugin(config: config))
#if Portadas
        let covers = BookCoversPlugin()
        PluginRegistry.shared.register(covers)
        _covers = State(wrappedValue: covers)
#endif
        _config = State(wrappedValue: config)
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            rootContent
#if Portadas && !canImport(SwiftOpenUI)
                .task(id: coverSyncKey) {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard !Task.isCancelled else { return }
                    await covers.syncCovers(for: viewModel.books)
                }
#endif
        }
#if os(macOS)
        .defaultSize(width: 1060, height: 740)
#endif
    }

    @ViewBuilder
    private var rootContent: some View {
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
#if Portadas
        .environment(covers)
#endif
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
#if Portadas
        .environment(covers)
#endif
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
#if Portadas
        .environment(covers)
#endif
#endif
    }

#if Portadas
    private var coverSyncKey: String {
        viewModel.books
            .map { "\($0.id.uuidString)|\($0.title)|\($0.author ?? "")" }
            .joined(separator: ";")
    }
#endif
}
