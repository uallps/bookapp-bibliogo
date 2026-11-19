import SwiftUI

/// F5 Estadísticas: pantalla completa con el resumen y métricas de la biblioteca.
struct StatisticsView: View {
    let statistics: BookStatistics

    init(statistics: BookStatistics) {
        self.statistics = statistics
    }

    init(books: [Book]) {
        self.statistics = BookStatistics(books: books)
    }

    var body: some View {
        Form {
            Section(header: Text("Resumen general")) {
                HStack {
                    Label("Total de libros", systemImage: "books.vertical")
                    Spacer()
                    Text("\(statistics.totalBooks)")
                        .bold()
                }
                HStack {
                    Label("Completados", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(statistics.completedCount) de \(statistics.totalBooks)")
                        .bookCaption()
                    Text("(\(Int(statistics.completionPercentage))%)")
                        .bookCaption(color: .green)
                }
            }

            Section(header: Text("Recuento por estado")) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    HStack {
                        Label(status.rawValue, systemImage: status.systemImage)
                            .foregroundColor(status.color)
                        Spacer()
                        Text("\(statistics.count(for: status)) libros")
                        Text("(\(Int(statistics.percentage(for: status)))%)")
                            .bookCaption()
                    }
                }
            }

            if statistics.totalBooks > 0 {
                Section(header: Text("Estado de la biblioteca")) {
                    Text(summaryMessage)
                        .bookCaption()
                }
            }
        }
        .navigationTitle("Estadísticas")
    }

    private var summaryMessage: String {
        if statistics.completedCount == statistics.totalBooks {
            return "¡Enhorabuena! Has leído todos los libros de tu biblioteca."
        } else if statistics.readingCount > 0 {
            return "Tienes \(statistics.readingCount) libro(s) en curso. ¡Sigue así!"
        } else {
            return "Tienes \(statistics.pendingCount) libro(s) pendientes por comenzar."
        }
    }
}
