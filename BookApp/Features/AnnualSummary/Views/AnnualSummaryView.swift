#if ResumenAnual
import SwiftUI

/// O4 Resumen anual: pantalla propia del plugin, en la barra lateral.
/// Recibe el plugin (no lo busca en el entorno) y solo dibuja lo que este calcula.
struct AnnualSummaryView: View {
    let plugin: AnnualSummaryPlugin

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
        let summary = plugin.summary
        let withoutDate = plugin.booksWithoutDate
#if !canImport(SwiftOpenUI)
        return appleBody(summary: summary, withoutDate: withoutDate)
#else
        return openUIBody(summary: summary, withoutDate: withoutDate)
#endif
    }

    // MARK: - Textos (se montan como String para que se vean igual en todas las plataformas)

    /// El año sin separador de miles ("2026", no "2.026").
    private func yearText(_ summary: AnnualSummary) -> String {
        String(summary.year)
    }

    private func booksText(_ count: Int) -> String {
        count == 1 ? "1 libro" : "\(count) libros"
    }

    private func pagesText(_ summary: AnnualSummary) -> String {
        summary.pagesRead > 0 ? "\(summary.pagesRead)" : "—"
    }

    private func busiestMonthText(_ summary: AnnualSummary) -> String {
        guard let month = summary.busiestMonth else { return "—" }
        return month.name
    }

    private func ratingText(_ rating: Double) -> String {
        String(format: "%.1f", rating)
    }

    private func emptyText(_ summary: AnnualSummary) -> String {
        "Aún no has terminado ningún libro en " + yearText(summary)
            + ". Cuando marques uno como Terminado, aparecerá aquí."
    }

    private func withoutDateText(_ books: [Book]) -> String {
        let titles = books.map(\.title).joined(separator: ", ")
        return booksText(books.count) + " terminados sin fecha: " + titles
            + ". Ábrelos y pulsa «Apuntar como terminado hoy» para que cuenten."
    }

#if !canImport(SwiftOpenUI)
    // MARK: - Apple

    private func appleBody(summary: AnnualSummary, withoutDate: [Book]) -> some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    appleHeader(summary)
                    appleFigures(summary)

                    if let best = summary.bestRated {
                        appleBestRated(best)
                    }

                    if summary.months.isEmpty {
                        appleNote(icon: "book.closed", text: emptyText(summary))
                    } else {
                        appleMonths(summary)
                    }

                    if !withoutDate.isEmpty {
                        appleNote(icon: "calendar.badge.exclamationmark", text: withoutDateText(withoutDate))
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

    private func appleHeader(_ summary: AnnualSummary) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                    Text("ESPACIO SERENO · RESUMEN ANUAL")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                }
                Text(verbatim: "Tu año lector " + yearText(summary))
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                Text("Lo que has terminado, mes a mes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                appleYearButton(systemImage: "chevron.left", enabled: plugin.canMoveToPreviousYear) {
                    plugin.moveYear(by: -1)
                }
                appleYearButton(systemImage: "chevron.right", enabled: plugin.canMoveToNextYear) {
                    plugin.moveYear(by: 1)
                }
            }
        }
    }

    private func appleYearButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.bookSageSurface(for: colorScheme)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    private func appleFigures(_ summary: AnnualSummary) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            appleFigure(value: "\(summary.finishedCount)", label: "Terminados", icon: "checkmark.circle.fill")
            appleFigure(value: pagesText(summary), label: "Páginas", icon: "book.pages")
            appleFigure(value: busiestMonthText(summary), label: "Mes más lector", icon: "sparkles")
        }
    }

    private func appleFigure(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.bookSageSurface(for: colorScheme)))
            Text(verbatim: value)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 14)
    }

    private func appleBestRated(_ best: AnnualSummary.BestRated) -> some View {
        HStack(spacing: 14) {
            BookCoverView(title: best.book.title, author: best.book.author, width: 46, height: 66)
            VStack(alignment: .leading, spacing: 4) {
                Text("EL MEJOR VALORADO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text(best.book.title)
                    .font(.system(.headline, design: .serif))
                if let author = best.book.author, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text(verbatim: ratingText(best.rating))
                    .font(.subheadline.weight(.bold))
            }
            .foregroundColor(.bookStar)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.bookStarSurface(for: colorScheme)))
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 16)
    }

    private func appleMonths(_ summary: AnnualSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MES A MES")
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundColor(.secondary)

            ForEach(summary.months) { month in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(month.name)
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                        Spacer()
                        Text(verbatim: booksText(month.entries.count))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ForEach(month.entries) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.book.title)
                                    .font(.subheadline)
                                if let author = entry.book.author, !author.isEmpty {
                                    Text(author)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(verbatim: SpanishDate.short(entry.finishedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private func appleNote(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            Text(verbatim: text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 14)
    }
#endif

    // MARK: - Linux y Windows

    private func openUIBody(summary: AnnualSummary, withoutDate: [Book]) -> some View {
        Form {
            Section(header: Text("Año")) {
                HStack(spacing: 12) {
                    Button("Año anterior") {
                        plugin.moveYear(by: -1)
                    }
                    Text(yearText(summary))
                        .font(.headline)
                    Button("Año siguiente") {
                        plugin.moveYear(by: 1)
                    }
                }
            }

            Section(header: Text("En cifras")) {
                Text("Terminados: " + booksText(summary.finishedCount))
                Text("Páginas leídas: " + pagesText(summary))
                Text("Mes más lector: " + busiestMonthText(summary))
                if let best = summary.bestRated {
                    Text("Mejor valorado: " + best.book.title + " (" + ratingText(best.rating) + ")")
                }
            }

            Section(header: Text("Mes a mes")) {
                if summary.months.isEmpty {
                    Text(emptyText(summary))
                        .bookCaption()
                }
                ForEach(summary.months) { month in
                    Text(month.name + " · " + booksText(month.entries.count))
                        .font(.headline)
                    ForEach(month.entries) { entry in
                        HStack(spacing: 8) {
                            Text(entry.book.title)
                            Text(SpanishDate.short(entry.finishedAt))
                                .bookCaption()
                        }
                    }
                }
            }

            if !withoutDate.isEmpty {
                Section(header: Text("Sin fecha")) {
                    Text(withoutDateText(withoutDate))
                        .bookCaption()
                }
            }
        }
        .navigationTitle("Resumen anual")
    }
}
#endif
