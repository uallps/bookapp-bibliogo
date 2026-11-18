import Foundation

/// F2 Notas y citas: una nota o cita asociada a un libro.
/// Va aparte de Book y se enlaza por `bookID`, así el Core no depende de F2.
/// El tipo se compila siempre; lo que depende del trait Notas es dónde se guarda
/// y dónde se muestra, siguiendo el mismo patrón que ReadingProgress.
struct BookNote: Identifiable, Codable {
    var id = UUID()
    var bookID: UUID
    var kind: NoteKind
    /// Contenido de la nota o texto de la cita.
    var text: String
    /// Número de página (opcional, relevante sobre todo en citas).
    var page: Int?
    var createdAt: Date

    init(bookID: UUID, kind: NoteKind = .note, text: String = "", page: Int? = nil) {
        self.bookID = bookID
        self.kind = kind
        self.text = text
        self.page = page
        self.createdAt = Date()
    }
}

/// Distingue si el registro es una nota personal o una cita textual del libro.
enum NoteKind: String, Codable, CaseIterable {
    case note  = "Nota"
    case quote = "Cita"
}
