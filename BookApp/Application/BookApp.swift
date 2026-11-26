import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Biblioteca y Ajustes.
    @State private var config = AppConfig()
    @State private var viewModel = BookListViewModel()
    @State private var selection: String? = "biblioteca"
    /// F3 Categorías: plugin común, se crea y se registra siempre (sin trait).
    @State private var categories: CategoryPlugin
#if ColaLectura
    /// O8 Cola de lectura: plugin opcional activado con el trait `ColaLectura`.
    @State private var readingQueue: ReadingQueuePlugin
#endif
#if Portadas
    /// O7 Foto de la portada: plugin opcional activado con el trait `Portadas`.
    @State private var covers: BookCoversPlugin
#endif

    /// Los plugins se crean y se registran una sola vez, al arrancar la app.
    init() {
        let categories = CategoryPlugin()
        PluginRegistry.shared.register(categories)
        _categories = State(wrappedValue: categories)
#if ColaLectura
        let readingQueue = ReadingQueuePlugin()
        PluginRegistry.shared.register(readingQueue)
        _readingQueue = State(wrappedValue: readingQueue)
#endif
#if Portadas
        let covers = BookCoversPlugin()
        PluginRegistry.shared.register(covers)
        _covers = State(wrappedValue: covers)
#endif
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
#if ColaLectura
            NavigationStack {
                readingQueueView
            }
            .tabItem { Label("Cola", systemImage: "list.number") }
#endif
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
#if ColaLectura
        .environment(readingQueue)
#endif
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
#if ColaLectura
                    NavigationLink(value: "cola") {
                        Label("Cola de lectura", systemImage: "list.number")
                    }
#endif
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
#if ColaLectura
            case "cola":
                NavigationStack {
                    readingQueueView
                }
#endif
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
#if ColaLectura
        .environment(readingQueue)
#endif
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
#if ColaLectura
                NavigationLink(value: "cola") {
                    Label("Cola de lectura", systemImage: "list.number")
                }
#endif
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
#if ColaLectura
            case "cola":
                NavigationStack {
                    readingQueueView
                }
#endif
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
#if ColaLectura
        .environment(readingQueue)
#endif
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

#if ColaLectura
    private var readingQueueView: some View {
        ReadingQueueView(books: viewModel.books) { bookID in
            if var book = viewModel.book(id: bookID), book.status == .pendiente {
                book.status = .leyendo
                viewModel.updateBook(book)
            }
        }
    }
#endif
}
