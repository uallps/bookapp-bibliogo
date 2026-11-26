import Foundation

/// F3 Categorías: un enlace entre un libro y una de sus categorías.
/// Es un dato del plugin, no de `Book`: se une al libro por su id. Un libro con
/// varias categorías tiene un enlace por cada una.
struct BookCategory: Codable, Hashable {
    let bookID: UUID
    let categoryID: UUID
}
