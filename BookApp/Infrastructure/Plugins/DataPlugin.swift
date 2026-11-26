import Foundation

/// Plugin con datos propios ligados a los libros. El registro le avisa de lo que
/// pasa en el Core (patrón observador), para que mantenga sus datos al día.
protocol DataPlugin: FeaturePlugin {
    /// Antes de borrar el libro: todavía se puede consultar.
    func willDeleteBook(_ book: Book)
    /// Después de borrarlo: ya solo queda su id.
    func didDeleteBook(id: UUID)
    /// El libro ha cambiado de estado (por ejemplo, de Leyendo a Terminado).
    func didChangeStatus(of book: Book, from oldStatus: ReadingStatus)
}

/// Por defecto no se hace nada: cada plugin implementa solo los avisos que le interesan.
extension DataPlugin {
    func willDeleteBook(_ book: Book) {}
    func didDeleteBook(id: UUID) {}
    func didChangeStatus(of book: Book, from oldStatus: ReadingStatus) {}
}
