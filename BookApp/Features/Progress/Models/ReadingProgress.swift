import Foundation

/// F1 Progreso: total de páginas, página actual y porcentaje leído.
/// Va aparte de Book y se enlaza por `bookID`, así el Core no depende de F1.
/// Forma parte de todos los productos de la línea.
struct ReadingProgress: Codable {
    var bookID: UUID
    var totalPages: Int
    var currentPage: Int

    /// Porcentaje leído, de 0 a 100.
    var percentage: Int {
        guard totalPages > 0 else { return 0 }
        return min(currentPage, totalPages) * 100 / totalPages
    }
}
