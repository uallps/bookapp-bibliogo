import SwiftUI

// El tema de la app: colores, iconos y estilos en un solo sitio, añadidos con extensiones.
// Para cambiar el aspecto se toca este fichero, no las vistas.

extension Color {
    /// Color principal de BookApp.
    static let bookAccent = Color(red: 0.42, green: 0.30, blue: 0.20)
}

/// Estilo del texto secundario de las filas (autor, estado, progreso).
struct CaptionStyle: ViewModifier {
    var color: Color = .secondary

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(color)
    }
}

extension View {
    /// Aplica el estilo de texto secundario: `Text("…").bookCaption()`,
    /// o con otro color: `.bookCaption(color: .green)`.
    func bookCaption(color: Color = .secondary) -> some View {
        modifier(CaptionStyle(color: color))
    }
}

extension ReadingStatus {
    /// Icono del botón de la fila. Es aspecto, por eso está aquí y no en el modelo.
    var systemImage: String {
        switch self {
        case .pendiente: return "circle"
        case .leyendo: return "bookmark"
        case .terminado: return "checkmark.circle.fill"
        }
    }

    /// Color del estado en la fila.
    var color: Color {
        switch self {
        case .pendiente: return .secondary
        case .leyendo: return .orange
        case .terminado: return .green
        }
    }
}

#if Progreso
extension ReadingProgress {
    /// Color del progreso: verde al terminar. Solo existe en el producto con progreso.
    var color: Color {
        percentage >= 100 ? .green : .secondary
    }
}
#endif
