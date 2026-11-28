#if Autores
import SwiftUI

/// O5 Autores encima de la biblioteca.
/// - En Mac: un menú para elegir autor y, con un filtro activo, una píldora «Autor: X»
///   con un botón para quitarlo.
/// - En Linux y Windows: solo la fila «Autor: X» con su botón (el plugin no la muestra
///   sin filtro). Ahí no hay selector con todos los autores, para no repetir sus nombres
///   en la biblioteca.
struct AuthorFilterView: View {
    /// Nombre del autor del filtro, o nil si no hay filtro.
    let activeName: String?
    /// Los autores para el menú (solo en Mac).
    let authors: [AuthorSummary]
    let onSelect: (AuthorSummary) -> Void
    let onClear: () -> Void

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private var activeText: String {
        "Autor: " + (activeName ?? "")
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleBody
#else
        HStack(spacing: 12) {
            Text(activeText)
            Button("Quitar filtro de autor") {
                onClear()
            }
        }
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleBody: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(authors) { author in
                    Button {
                        onSelect(author)
                    } label: {
                        Text(verbatim: author.name + "  (" + author.booksText + ")")
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "person.2")
                        .font(.caption2)
                    Text("Filtrar por autor")
                        .font(.caption.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.bookCard(for: colorScheme).opacity(0.7)))
                .overlay(Capsule().stroke(Color.bookBorder(for: colorScheme), lineWidth: 1))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()

            if activeName != nil {
                HStack(spacing: 6) {
                    Image(systemName: AuthorProfile.systemImage)
                        .font(.caption2)
                    Text(verbatim: activeText)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { onClear() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Quitar filtro de autor")
                }
                .foregroundColor(Color.bookSageForeground(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                .overlay(
                    Capsule().stroke(Color.bookAccentAdaptive(for: colorScheme).opacity(0.35), lineWidth: 1)
                )
            }

            Spacer(minLength: 0)
        }
    }
#endif
}
#endif
