import SwiftUI

/// F5 Estadísticas: sección que resume las métricas de lectura (total y por estado).
struct StatisticsSection: View {
    let statistics: BookStatistics

    var body: some View {
        Section(header: Text("Estadísticas de lectura")) {
            HStack {
                Label("Total de libros", systemImage: "books.vertical")
                Spacer()
                Text("\(statistics.totalBooks)")
                    .bold()
            }
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                HStack {
                    Label(status.rawValue, systemImage: status.systemImage)
                        .foregroundColor(status.color)
                    Spacer()
                    Text("\(statistics.count(for: status))")
                        .bookCaption()
                    Text("(\(Int(statistics.percentage(for: status)))%)")
                        .bookCaption()
                }
            }
        }
    }
}
