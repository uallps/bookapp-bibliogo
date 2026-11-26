import SwiftUI

/// F1 Progreso: sección del detalle para indicar el total de páginas y la página actual.
struct ProgressSection: View {
    @Binding var progress: ReadingProgress

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Progreso de lectura", systemImage: "book.pages")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                Text("\(progress.percentage) %")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookSageForeground(for: colorScheme))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
            }

            BiblioProgressBar(
                progress: Double(progress.percentage) / 100.0,
                color: Color.bookAccentAdaptive(for: colorScheme),
                height: 8
            )

            Stepper("Páginas totales: \(progress.totalPages)", value: $progress.totalPages, in: 0...5000, step: 10)
                .font(.subheadline)
            Stepper("Página actual: \(progress.currentPage)", value: $progress.currentPage, in: 0...max(progress.totalPages, 0))
                .font(.subheadline)
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
#else
        Section(header: Text("Progreso")) {
            Stepper("Páginas totales: \(progress.totalPages)", value: $progress.totalPages, in: 0...5000, step: 10)
            Stepper("Página actual: \(progress.currentPage)", value: $progress.currentPage, in: 0...max(progress.totalPages, 0))
            Text(percentageText)
        }
#endif
    }

    /// Se monta como String para que el % se muestre tal cual en todas las plataformas.
    private var percentageText: String {
        "Leído: \(progress.percentage) %"
    }
}
