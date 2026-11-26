#if ResumenAnual
import SwiftUI

/// O4 Resumen anual en el detalle de un libro terminado: cuándo se terminó, o un botón
/// para apuntarlo hoy si no se sabe (libros que ya estaban terminados antes del resumen).
struct FinishDateSection: View {
    let finishedAt: Date?
    let markFinishedToday: () -> Void

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        VStack(alignment: .leading, spacing: 10) {
            Label("Resumen anual", systemImage: "calendar")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))

            if let finishedAt {
                Text(finishedText(finishedAt))
                    .font(.subheadline)
            } else {
                Text(unknownText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button {
                    markFinishedToday()
                } label: {
                    Label("Apuntar como terminado hoy", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
#else
        Section(header: Text("Resumen anual")) {
            if let finishedAt {
                Text(finishedText(finishedAt))
            } else {
                Text(unknownText)
                    .bookCaption()
                Button("Apuntar como terminado hoy") {
                    markFinishedToday()
                }
            }
        }
#endif
    }

    private func finishedText(_ date: Date) -> String {
        "Terminado el " + SpanishDate.long(date)
    }

    private var unknownText: String {
        "No se sabe cuándo lo terminaste, así que no cuenta en ningún año."
    }
}
#endif
