import Foundation

/// Libro del Core. Solo tiene lo que comparten todas las variantes:
/// identificador, título, autor opcional y estado de lectura.
/// Los datos de las features (progreso, notas, categorías...) van en sus propios
/// tipos y se enlazan por `bookID`, para que Book no dependa de ninguna feature.
/// Codable: el libro se puede guardar y leer en JSON.
struct Book: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String?
    var status: ReadingStatus = .pendiente
}
