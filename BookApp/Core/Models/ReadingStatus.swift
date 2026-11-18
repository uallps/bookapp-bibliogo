/// Estado de lectura de un libro (obligatorio en el Core).
enum ReadingStatus: String, CaseIterable, Codable {
    case pendiente = "Pendiente"
    case leyendo = "Leyendo"
    case terminado = "Terminado"

    /// El estado siguiente al pulsar el botón de la fila:
    /// Pendiente → Leyendo → Terminado → Pendiente.
    var next: ReadingStatus {
        switch self {
        case .pendiente: return .leyendo
        case .leyendo: return .terminado
        case .terminado: return .pendiente
        }
    }
}
