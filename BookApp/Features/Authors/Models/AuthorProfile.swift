#if Autores
import Foundation

/// O5 Autores: la ficha de un autor. No va dentro de `Book`: se enlaza con los libros
/// por el nombre normalizado del campo `author` que ya tiene el núcleo.
struct AuthorProfile: Identifiable, Codable, Hashable {
    /// Nombre tal y como se escribió la primera vez (para mostrarlo).
    var name: String
    var nationality: String?
    var birthYear: Int?
    var notes: String = ""

    /// Clave de enlace con los libros: el nombre normalizado.
    var key: String { AuthorProfile.key(for: name) }
    var id: String { key }

    /// Si la ficha tiene algo que enseñar en el detalle del libro.
    var hasInfo: Bool {
        !(nationality ?? "").isEmpty || birthYear != nil || !notes.isEmpty
    }

    /// Nombre normalizado: sin mayúsculas ni espacios sobrantes.
    /// "  frank   HERBERT " y "Frank Herbert" son el mismo autor.
    static func key(for name: String) -> String {
        tidy(name).lowercased()
    }

    /// El nombre sin espacios sobrantes, conservando las mayúsculas.
    static func tidy(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
#endif
