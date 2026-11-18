import SwiftUI

#if Progreso
/// F1 Progreso: sección del detalle para indicar el total de páginas y la página actual.
/// Solo se compila en el producto con el trait Progreso.
struct ProgressSection: View {
    @Binding var progress: ReadingProgress

    var body: some View {
        Section(header: Text("Progreso")) {
            Stepper("Páginas totales: \(progress.totalPages)", value: $progress.totalPages, in: 0...5000, step: 10)
            Stepper("Página actual: \(progress.currentPage)", value: $progress.currentPage, in: 0...max(progress.totalPages, 0))
            Text(percentageText)
        }
    }

    /// Se monta como String para que el % se muestre tal cual en todas las plataformas.
    private var percentageText: String {
        "Leído: \(progress.percentage) %"
    }
}
#endif
