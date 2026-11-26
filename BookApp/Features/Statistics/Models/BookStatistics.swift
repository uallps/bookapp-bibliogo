import Foundation

/// F5 Estadísticas: cálculo de métricas sobre la colección de libros.
/// Se calculan a partir de los datos del Core (libros y estados de lectura).
/// Proporciona el número total de libros y el recuento por cada estado.
struct BookStatistics {
    /// Número total de libros en la biblioteca.
    let totalBooks: Int
    /// Libros en estado pendiente.
    let pendingCount: Int
    /// Libros en lectura activa.
    let readingCount: Int
    /// Libros completados.
    let completedCount: Int

    init(books: [Book] = []) {
        self.totalBooks = books.count
        self.pendingCount = books.filter { $0.status == .pendiente }.count
        self.readingCount = books.filter { $0.status == .leyendo }.count
        self.completedCount = books.filter { $0.status == .terminado }.count
    }

    /// Recuento de libros para un estado de lectura concreto.
    func count(for status: ReadingStatus) -> Int {
        switch status {
        case .pendiente: return pendingCount
        case .leyendo: return readingCount
        case .terminado: return completedCount
        }
    }

    /// Porcentaje de libros en un estado respecto al total (0.0 a 100.0).
    func percentage(for status: ReadingStatus) -> Double {
        guard totalBooks > 0 else { return 0 }
        return (Double(count(for: status)) / Double(totalBooks)) * 100
    }

    /// Porcentaje global de libros terminados sobre el total.
    var completionPercentage: Double {
        percentage(for: .terminado)
    }
}
