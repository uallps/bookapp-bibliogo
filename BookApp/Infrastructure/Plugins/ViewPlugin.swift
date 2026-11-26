import SwiftUI

/// Plugin que aporta vistas en puntos fijos de la app. El núcleo pide al registro las
/// vistas de los plugins activos y las muestra sin saber de quién son.
///
/// Puntos de extensión:
/// - la fila de un libro, su detalle y la pantalla de Ajustes (como en la sesión 8);
/// - la cabecera de la biblioteca (filtros, avisos, sugerencias) y qué libros se ven;
/// - una pantalla propia en la barra lateral (Logros, Resumen anual...).
///
/// Todos tienen una implementación por defecto que no aporta nada: cada plugin
/// implementa solo los puntos que necesita.
protocol ViewPlugin: FeaturePlugin {
    /// Cada plugin elige el tipo de sus vistas (en un protocolo no vale `some View`).
    associatedtype RowContent: View = EmptyView
    associatedtype DetailContent: View = EmptyView
    associatedtype SettingsContent: View = EmptyView
    associatedtype LibraryContent: View = EmptyView
    associatedtype ScreenContent: View = EmptyView

    /// Si sus vistas se muestran ahora, normalmente según un ajuste.
    /// El ajuste se ve siempre, para poder volver a encenderlo.
    var isEnabled: Bool { get }

    /// Lo que el plugin añade a la fila de un libro.
    @ViewBuilder func bookRowView(for book: Book) -> RowContent
    /// Lo que el plugin añade al detalle de un libro, debajo de las secciones del núcleo.
    @ViewBuilder func bookDetailView(for book: Book) -> DetailContent
    /// Sus ajustes, en la pantalla de Ajustes.
    @ViewBuilder func settingsView() -> SettingsContent

    /// Lo que añade encima de la lista de libros (un filtro, una sugerencia...).
    @ViewBuilder func libraryView() -> LibraryContent
    /// Los libros que se ven en la biblioteca. Por defecto, todos.
    func filterBooks(_ books: [Book]) -> [Book]

    /// Título de su pantalla en la barra lateral. nil: no tiene pantalla propia.
    var screenTitle: String? { get }
    /// Icono de su pantalla en la barra lateral.
    var screenSystemImage: String { get }
    /// Su pantalla propia.
    @ViewBuilder func screenView() -> ScreenContent
}

/// Por defecto el plugin está activo y no aporta nada en ningún punto.
extension ViewPlugin {
    var isEnabled: Bool { true }

    func bookRowView(for book: Book) -> EmptyView { EmptyView() }
    func bookDetailView(for book: Book) -> EmptyView { EmptyView() }
    func settingsView() -> EmptyView { EmptyView() }

    func libraryView() -> EmptyView { EmptyView() }
    func filterBooks(_ books: [Book]) -> [Book] { books }

    var screenTitle: String? { nil }
    var screenSystemImage: String { "square.grid.2x2" }
    func screenView() -> EmptyView { EmptyView() }
}
