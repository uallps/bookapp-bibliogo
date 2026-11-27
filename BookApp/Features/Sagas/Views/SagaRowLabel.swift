#if Sagas
import SwiftUI

extension Saga {
    /// O6: icono de las sagas (fila, detalle, ajuste y barra lateral).
#if !canImport(SwiftOpenUI)
    static let systemImage = "books.vertical.circle"
#else
    // SwiftOpenUI no tiene todos los SF Symbols: uno parecido que sí tiene.
    static let systemImage = "square.on.square"
#endif
    /// O6: color de la saga en la fila (armonizado con la paleta BiblioGo).
    static let color = Color(red: 0.42, green: 0.31, blue: 0.20)
}

/// O6 Sagas en la fila de un libro: por ejemplo "El Señor de los Anillos · nº 2".
struct SagaRowLabel: View {
    let text: String

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        HStack(spacing: 4) {
            Image(systemName: Saga.systemImage)
                .font(.system(size: 9))
            Text(verbatim: text)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .foregroundColor(colorScheme == .dark ? Color(red: 0.86, green: 0.74, blue: 0.58) : Saga.color)
#else
        HStack(spacing: 3) {
            Image(systemName: Saga.systemImage)
                .foregroundColor(Saga.color)
            Text(text)
                .bookCaption(color: Saga.color)
        }
#endif
    }
}
#endif
