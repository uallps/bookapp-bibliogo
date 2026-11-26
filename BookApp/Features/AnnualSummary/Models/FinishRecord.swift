#if ResumenAnual
import Foundation

/// O4 Resumen anual: cuándo se terminó un libro. Va enlazado por `bookID`, fuera de
/// `Book`, y se guarda en el fichero del plugin.
struct FinishRecord: Codable, Equatable {
    var bookID: UUID
    var finishedAt: Date
}
#endif
