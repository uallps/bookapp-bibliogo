import Foundation

/// F3 Categorías: todo lo que guarda el plugin, las categorías y sus enlaces con los libros.
/// Se guarda entero en un solo fichero, categories.json, para que nunca haya un enlace
/// guardado sin su categoría.
struct CategoryData: Codable {
    var categories: [Category] = []
    var links: [BookCategory] = []

    /// Categorías de partida, la primera vez que se abre la app. No se enlazan a los
    /// libros de ejemplo porque estos cambian de id en cada arranque hasta que se guardan.
    static let sample = CategoryData(categories: [
        Category(name: "Novela"),
        Category(name: "Ciencia ficción"),
        Category(name: "Ensayo"),
    ])

    /// Categorías de un libro, en el orden de la lista de la biblioteca.
    func categories(for bookID: UUID) -> [Category] {
        let ids = Set(links.filter { $0.bookID == bookID }.map(\.categoryID))
        return categories.filter { ids.contains($0.id) }
    }

    /// Ids de los libros que tienen esa categoría.
    func bookIDs(in categoryID: UUID) -> Set<UUID> {
        Set(links.filter { $0.categoryID == categoryID }.map(\.bookID))
    }
}
