import SwiftUI

/// Registro de plugins. El núcleo habla con el registro, nunca con un plugin concreto.
final class PluginRegistry {
    /// Un único registro para toda la app (patrón Singleton).
    static let shared = PluginRegistry()

    /// Los plugins registrados, en el orden en que se registraron.
    private(set) var plugins: [FeaturePlugin] = []

    private init() {}

    /// Añade un plugin. Registrar dos veces el mismo no hace nada.
    func register(_ plugin: FeaturePlugin) {
        guard !plugins.contains(where: { $0 === plugin }) else { return }
        plugins.append(plugin)
        print("Plugin registrado: \(plugin.name)")
    }

    /// Los plugins que quieren saber qué pasa con los libros.
    private var dataPlugins: [DataPlugin] {
        plugins.compactMap { $0 as? DataPlugin }
    }

    /// Avisa a los plugins de datos de que un libro se va a borrar.
    func notifyBookWillBeDeleted(_ book: Book) {
        for plugin in dataPlugins {
            plugin.willDeleteBook(book)
        }
    }

    /// Avisa a los plugins de datos de que un libro se ha borrado.
    func notifyBookDidDelete(id: UUID) {
        for plugin in dataPlugins {
            plugin.didDeleteBook(id: id)
        }
    }

    /// Avisa a los plugins de datos de que un libro ha cambiado de estado.
    func notifyStatusChanged(of book: Book, from oldStatus: ReadingStatus) {
        for plugin in dataPlugins {
            plugin.didChangeStatus(of: book, from: oldStatus)
        }
    }

    // MARK: - Vistas de los plugins

    /// Los plugins que aportan vistas, en orden de registro.
    private var viewPlugins: [any ViewPlugin] {
        plugins.compactMap { $0 as? any ViewPlugin }
    }

    /// Los plugins de vista activos.
    private var enabledViewPlugins: [any ViewPlugin] {
        viewPlugins.filter(\.isEnabled)
    }

    /// Lo que añaden a la fila de un libro los plugins activos.
    func bookRowViews(for book: Book) -> [PluginView] {
        enabledViewPlugins.compactMap { plugin in
            PluginView(id: plugin.name, plugin.bookRowView(for: book))
        }
    }

    /// Lo que añaden al detalle de un libro los plugins activos.
    func bookDetailViews(for book: Book) -> [PluginView] {
        enabledViewPlugins.compactMap { plugin in
            PluginView(id: plugin.name, plugin.bookDetailView(for: book))
        }
    }

    /// Los ajustes de todos los plugins, también de los apagados: así se pueden volver a encender.
    func settingsViews() -> [PluginView] {
        viewPlugins.compactMap { plugin in
            PluginView(id: plugin.name, plugin.settingsView())
        }
    }

    /// Lo que añaden encima de la lista de libros los plugins activos.
    func libraryViews() -> [PluginView] {
        enabledViewPlugins.compactMap { plugin in
            PluginView(id: plugin.name, plugin.libraryView())
        }
    }

    /// Los libros que se ven en la biblioteca: cada plugin activo aplica su filtro, en orden.
    /// Con un plugin apagado no se aplica su filtro, para que no esconda libros.
    func filteredBooks(_ books: [Book]) -> [Book] {
        enabledViewPlugins.reduce(books) { visible, plugin in
            plugin.filterBooks(visible)
        }
    }

    /// Las pantallas propias de los plugins activos, para la barra lateral.
    func screens() -> [PluginScreen] {
        enabledViewPlugins.compactMap { plugin in
            guard let title = plugin.screenTitle else { return nil }
            return PluginScreen(
                id: plugin.name,
                title: title,
                systemImage: plugin.screenSystemImage,
                view: AnyView(plugin.screenView())
            )
        }
    }

    /// La pantalla de un plugin a partir de su etiqueta en la barra lateral.
    func screen(tag: String?) -> PluginScreen? {
        screens().first { $0.tag == tag }
    }
}

/// Una vista aportada por un plugin, lista para un `ForEach`.
struct PluginView: Identifiable {
    /// El nombre del plugin: no hay dos iguales.
    let id: String
    /// Vistas de tipos distintos guardadas con un tipo común (borrado de tipo).
    let view: AnyView

    /// nil si el plugin no aporta nada en ese punto (su vista es EmptyView),
    /// para no dejar huecos vacíos en listas y formularios.
    init?(id: String, _ view: some View) {
        guard !(view is EmptyView) else { return nil }
        self.id = id
        self.view = AnyView(view)
    }
}

/// La pantalla propia de un plugin, para la barra lateral.
struct PluginScreen: Identifiable {
    /// El nombre del plugin.
    let id: String
    let title: String
    let systemImage: String
    let view: AnyView

    /// Valor de su enlace en la barra lateral, distinto de los del núcleo.
    var tag: String { "plugin:\(id)" }
}
