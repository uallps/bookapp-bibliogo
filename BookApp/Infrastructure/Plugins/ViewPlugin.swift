import SwiftUI

/// Plugin que aporta vistas en puntos fijos de la app. El núcleo pide al registro las
/// vistas de los plugins activos y las muestra sin saber de quién son.
///
/// Puntos de extensión:
/// - la fila de un libro, su detalle y la pantalla de Ajustes (como en la sesión 8);
/// - la cabecera de la biblioteca (filtros, avisos, sugerencias) y qué libros se ven;
/// - una pantalla propia en la barra lateral (Logros, Resumen anual...).
///
/// Las cinco vistas son obligatorias: en los puntos que no use, el plugin devuelve
/// `EmptyView()` y el registro no lo muestra. No tienen versión por defecto a propósito:
/// con una versión por defecto que devuelve `EmptyView`, Swift puede elegirla en lugar
/// de la del plugin al deducir el tipo de la vista, y la vista del plugin no se ve nunca.
protocol ViewPlugin: FeaturePlugin {
    /// Cada plugin elige el tipo de sus vistas (en un protocolo no vale `some View`).
    associatedtype RowContent: View
    associatedtype DetailContent: View
    associatedtype SettingsContent: View
    associatedtype LibraryContent: View
    associatedtype ScreenContent: View

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

/// Por defecto el plugin está activo, no filtra libros y no tiene pantalla propia.
/// (Solo lo que no es una vista: las vistas las implementa siempre el plugin.)
extension ViewPlugin {
    var isEnabled: Bool { true }
    func filterBooks(_ books: [Book]) -> [Book] { books }
    var screenTitle: String? { nil }
    var screenSystemImage: String { "square.grid.2x2" }
}
