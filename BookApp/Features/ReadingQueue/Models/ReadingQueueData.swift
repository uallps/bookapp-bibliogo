#if ColaLectura
import Foundation

/// O8 Cola de lectura: orden de los próximos libros que el usuario quiere leer.
/// Solo guarda los `bookID` en orden; los libros siguen viviendo en el Core.
struct ReadingQueueData: Codable, Equatable {
    var orderedBookIDs: [UUID]

    /// Cola de ejemplo inicial con el libro pendiente de muestra (Dune).
    static let sample = ReadingQueueData(
        orderedBookIDs: [UUID(uuidString: "6B1D2C4E-0001-4B00-8000-B00C0000D0E1")!]
    )
}
#endif
