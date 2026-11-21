import Foundation

/// F3 Categorías: el filtro de la biblioteca. Es lógica pura, sin interfaz, para poder
/// probarla sola. La selección es un String (no un UUID?) porque así las etiquetas del
/// Picker coinciden en todas las plataformas, también con SwiftOpenUI.
enum CategoryFilter {
    /// Selección que muestra todos los libros.
    static let all = "todas"

    /// Los libros que se ven con esa selección. Si la categoría elegida ya no existe
    /// (porque se ha borrado), se ven todos en lugar de una lista vacía sin explicación.
    static func books(_ books: [Book], selection: String, in data: CategoryData) -> [Book] {
        guard let categoryID = UUID(uuidString: selection),
              data.categories.contains(where: { $0.id == categoryID })
        else { return books }
        let ids = data.bookIDs(in: categoryID)
        return books.filter { ids.contains($0.id) }
    }
}
