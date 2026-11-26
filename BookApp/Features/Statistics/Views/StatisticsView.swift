import SwiftUI

/// F5 Estadísticas: pantalla completa con el resumen y métricas de la biblioteca, estilo sereno de BiblioGo.
struct StatisticsView: View {
    let statistics: BookStatistics

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    init(statistics: BookStatistics) {
        self.statistics = statistics
    }

    init(books: [Book]) {
        self.statistics = BookStatistics(books: books)
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleStatisticsBody
#else
        openUIStatisticsBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleStatisticsBody: some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    editorialHeader
                    kpiGrid
                    completionProgressCard
                    statusBreakdownCard

                    if statistics.totalBooks > 0 {
                        motivationCard
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 740)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var horizontalPadding: CGFloat {
#if os(macOS)
        return 28
#else
        return 18
#endif
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("ESPACIO SERENO · HÁBITOS")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }

            Text("Tu Viaje Lector")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Text("Un vistazo pausado a tu biblioteca, sin métricas obsesivas.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var kpiGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            kpiCard(
                value: "\(statistics.totalBooks)",
                label: "Total",
                icon: "books.vertical.fill",
                tint: Color.bookAccentAdaptive(for: colorScheme)
            )
            kpiCard(
                value: "\(statistics.readingCount)",
                label: "En curso",
                icon: "bookmark.fill",
                tint: Color.bookAccentAdaptive(for: colorScheme)
            )
            kpiCard(
                value: "\(statistics.completedCount)",
                label: "Leídos",
                icon: "checkmark.circle.fill",
                tint: Color(red: 0.20, green: 0.52, blue: 0.34)
            )
        }
    }

    private func kpiCard(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(tint)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(Color.bookSageSurface(for: colorScheme))
                )

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 14)
    }

    private var completionProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("PROGRESO GLOBAL")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                    Text("\(statistics.completedCount) de \(statistics.totalBooks) \(statistics.totalBooks == 1 ? "libro completado" : "libros completados")")
                        .font(.system(.headline, design: .serif))
                }
                Spacer()
                Text("\(Int(statistics.completionPercentage)) %")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color.bookSageForeground(for: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
            }

            BiblioProgressBar(
                progress: statistics.completionPercentage / 100.0,
                color: Color.bookAccentAdaptive(for: colorScheme),
                height: 9
            )
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private var statusBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECUENTO POR ESTADO")
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundColor(.secondary)

            ForEach(ReadingStatus.allCases, id: \.self) { status in
                let pct = statistics.percentage(for: status)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 10) {
                        Image(systemName: status.systemImage)
                            .font(.subheadline)
                            .foregroundColor(status == .leyendo ? Color.bookAccentAdaptive(for: colorScheme) : status.color)
                            .frame(width: 22)

                        Text(status.rawValue)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text(booksCountString(for: status))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(pct)) %")
                            .font(.caption.weight(.bold))
                            .foregroundColor(status == .leyendo ? Color.bookAccentAdaptive(for: colorScheme) : status.color)
                            .frame(minWidth: 38, alignment: .trailing)
                    }

                    BiblioProgressBar(
                        progress: pct / 100.0,
                        color: status == .leyendo ? Color.bookAccentAdaptive(for: colorScheme) : status.color,
                        height: 6
                    )
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private var motivationCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(Color.bookSageForeground(for: colorScheme))
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Color.bookCard(for: colorScheme))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("ESTADO DE TU BIBLIOTECA")
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundColor(Color.bookSageForeground(for: colorScheme))
                Text(summaryMessage)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.bookSageSurface(for: colorScheme))
        )
    }
#endif

    private var openUIStatisticsBody: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundColor(Color.bookAccent)
                        Text("ESPACIO SERENO • HÁBITOS")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(Color.bookAccent)
                    }
                    Text("Métricas de lectura consciente")
                        .font(.headline)
                    Text("Un vistazo pausado a tu viaje lector, sin métricas obsesivas.")
                        .font(.subheadline)
                        .bookCaption()
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Resumen general")) {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(Color.bookAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total de libros")
                            .font(.body)
                        Text("Colección en tu biblioteca")
                            .font(.caption)
                            .bookCaption()
                    }
                    Spacer()
                    Text("\(statistics.totalBooks)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 2)

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.22, green: 0.52, blue: 0.35))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Completados")
                            .font(.body)
                        Text("\(statistics.completedCount) de \(statistics.totalBooks) terminados")
                            .font(.caption)
                            .bookCaption()
                    }
                    Spacer()
                    Text("\(Int(statistics.completionPercentage)) %")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color(red: 0.22, green: 0.52, blue: 0.35))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.bookSage)
                        .cornerRadius(6)
                }
                .padding(.vertical, 2)
            }

            Section(header: Text("Recuento por estado")) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    HStack(spacing: 12) {
                        Image(systemName: status.systemImage)
                            .font(.title3)
                            .foregroundColor(status.color)

                        Text(status.rawValue)
                            .font(.body)

                        Spacer()

                        Text(booksCountString(for: status))
                            .bookCaption()

                        Text("(\(Int(statistics.percentage(for: status))) %)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(status.color)
                            .frame(minWidth: 44, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }
            }

            if statistics.totalBooks > 0 {
                Section(header: Text("Estado de la biblioteca")) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.title3)
                            .foregroundColor(Color.bookAccent)
                        Text(summaryMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Estadísticas")
    }

    private func booksCountString(for status: ReadingStatus) -> String {
        let count = statistics.count(for: status)
        return count == 1 ? "1 libro" : "\(count) libros"
    }

    private var summaryMessage: String {
        if statistics.completedCount == statistics.totalBooks {
            return "¡Enhorabuena! Has leído todos los libros de tu biblioteca."
        } else if statistics.readingCount == 1 {
            return "Tienes 1 libro en curso. ¡Disfruta de la lectura a tu propio ritmo!"
        } else if statistics.readingCount > 1 {
            return "Tienes \(statistics.readingCount) libros en curso. ¡Sigue así!"
        } else {
            let pending = statistics.pendingCount
            return pending == 1 ? "Tienes 1 libro pendiente por comenzar." : "Tienes \(pending) libros pendientes por comenzar."
        }
    }
}
