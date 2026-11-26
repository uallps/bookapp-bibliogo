import Foundation

/// F3 Categorías: una categoría con la que clasificar libros (Novela, Ensayo...).
/// Las categorías son una lista propia de la biblioteca: no van dentro de `Book`.
struct Category: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}
