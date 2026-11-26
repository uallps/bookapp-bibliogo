#if Portadas
import Foundation

/// O7 Foto de la portada: metadatos de la portada asociada a un libro.
/// La imagen se guarda en disco (`covers/<bookID>.jpg`) para funcionar sin conexión.
struct BookCoverEntry: Codable, Equatable, Identifiable {
    var id: UUID { bookID }
    let bookID: UUID
    var title: String
    var author: String?
    /// Nombre del fichero de imagen dentro de la carpeta `covers/`.
    var localFilename: String
    /// URL de origen si se descargó de internet (Open Library / Google Books).
    var remoteURL: String?
    /// `true` si la eligió manualmente el usuario (no se sobrescribe al editar título/autor).
    var isCustom: Bool = false
}
#endif
