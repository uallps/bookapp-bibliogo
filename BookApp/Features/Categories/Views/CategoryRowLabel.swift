import SwiftUI

extension Category {
    /// F3: icono de las categorías en la fila.
    static let systemImage = "tag"
    /// F3: icono del botón para crear una categoría.
    static let addSystemImage = "plus.circle"
    /// F3: color de las categorías en la fila (armonizado con la paleta BiblioGo).
    static let color = Color(red: 0.16, green: 0.44, blue: 0.44)
}

/// F3 Categorías en la fila de un libro: icono y nombres, por ejemplo "Novela · Clásicos".
struct CategoryRowLabel: View {
    let text: String

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        HStack(spacing: 4) {
            Image(systemName: Category.systemImage)
                .font(.system(size: 9))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                .lineLimit(1)
        }
#else
        HStack(spacing: 3) {
            Image(systemName: Category.systemImage)
                .foregroundColor(Category.color)
            Text(text)
                .bookCaption(color: Category.color)
        }
#endif
    }
}
