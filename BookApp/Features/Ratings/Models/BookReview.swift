import Foundation

/// F4 Valoraciones y reseñas: puntuación de 1 a 5 estrellas y reseña personal.
/// Va aparte de Book y se enlaza por `bookID`, así el Core no depende de F4.
/// El tipo se compila siempre; lo que depende del trait Valoraciones es dónde se guarda
/// y dónde se muestra, siguiendo el mismo patrón que ReadingProgress y BookNote.
struct BookReview: Identifiable, Codable {
    var id: UUID
    var bookID: UUID
    /// Nombre de quien escribe la valoración (otro usuario o el propio usuario).
    var userName: String
    /// Puntuación de 1 a 5 estrellas.
    var rating: Int
    /// Texto de la reseña o comentario opcional.
    var comment: String
    /// Fecha de publicación de la valoración.
    var date: Date
    /// Indica si la valoración fue creada por el usuario actual de la app.
    var isUserReview: Bool

    init(
        id: UUID = UUID(),
        bookID: UUID,
        userName: String,
        rating: Int,
        comment: String = "",
        date: Date = Date(),
        isUserReview: Bool = false
    ) {
        self.id = id
        self.bookID = bookID
        self.userName = userName
        self.rating = max(1, min(5, rating))
        self.comment = comment
        self.date = date
        self.isUserReview = isUserReview
    }
}

