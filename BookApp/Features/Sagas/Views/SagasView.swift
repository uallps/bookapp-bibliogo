#if Sagas
import SwiftUI

/// O6 Sagas: pantalla propia del plugin, en la barra lateral. Cada saga con sus libros en
/// orden y su estado, el siguiente por leer y cuántos van leídos.
/// Recibe el plugin (no lo busca en el entorno) y solo dibuja lo que este calcula.
struct SagasView: View {
    let plugin: SagaPlugin

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private let emptyText = "Aún no hay sagas. Abre un libro y créala en su sección «Saga»."
    private let noBooksText = "Esta saga aún no tiene libros: añádelos desde su detalle."

    private func nextText(_ progress: SagaProgress) -> String {
        if let next = progress.nextBook {
            return "Siguiente por leer: " + next.title
        }
        return progress.isCompleted ? "¡Saga terminada!" : noBooksText
    }

    var body: some View {
        let sagas = plugin.allProgress
#if !canImport(SwiftOpenUI)
        return appleBody(sagas: sagas)
#else
        return openUIBody(sagas: sagas)
#endif
    }

#if !canImport(SwiftOpenUI)
    // MARK: - Apple

    private func appleBody(sagas: [SagaProgress]) -> some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    appleHeader(count: sagas.count)

                    if sagas.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: Saga.systemImage)
                                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                            Text(verbatim: emptyText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 16)
                    }

                    ForEach(sagas) { progress in
                        appleSagaCard(progress)
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

    private func appleHeader(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: Saga.systemImage)
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("ESPACIO SERENO · SAGAS")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }
            Text("Sagas y series")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)
            Text("Tus historias por entregas, en orden, y cuál toca leer después.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func appleSagaCard(_ progress: SagaProgress) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: progress.saga.name)
                    .font(.system(.title3, design: .serif).bold())
                Spacer()
                Text(verbatim: progress.progressText)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Color.bookSageForeground(for: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
            }

            if !progress.books.isEmpty {
                BiblioProgressBar(
                    progress: Double(progress.finishedCount) / Double(progress.books.count),
                    color: Color.bookAccentAdaptive(for: colorScheme),
                    height: 6
                )
            }

            // El siguiente por leer, destacado.
            HStack(spacing: 10) {
                Image(systemName: progress.isCompleted ? "checkmark.seal.fill" : "arrow.right.circle.fill")
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text(verbatim: nextText(progress))
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.bookSageSurface(for: colorScheme))
            )

            ForEach(Array(progress.books.enumerated()), id: \.element.id) { index, book in
                HStack(spacing: 12) {
                    Text(verbatim: String(index + 1))
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    BookCoverView(title: book.title, author: book.author, width: 30, height: 43)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: book.title.isEmpty ? "Sin título" : book.title)
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .lineLimit(1)
                        if let author = book.author, !author.isEmpty {
                            Text(verbatim: author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Label(book.status.rawValue, systemImage: book.status.systemImage)
                        .font(.caption.weight(.medium))
                        .foregroundColor(book.status.color)
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
        .contextMenu {
            Button(role: .destructive) {
                plugin.removeSaga(id: progress.saga.id)
            } label: {
                Label("Eliminar saga", systemImage: "trash")
            }
        }
    }
#endif

    // MARK: - Linux y Windows

    private func openUIBody(sagas: [SagaProgress]) -> some View {
        Form {
            if sagas.isEmpty {
                Text(emptyText)
                    .bookCaption()
            }
            ForEach(sagas) { progress in
                Section(header: Text(progress.saga.name + " · " + progress.progressText)) {
                    Text(nextText(progress))
                        .font(.headline)
                    ForEach(0..<progress.books.count, id: \.self) { index in
                        HStack(spacing: 8) {
                            Text(String(index + 1) + ". " + progress.books[index].title)
                            Text(progress.books[index].status.rawValue)
                                .bookCaption(color: progress.books[index].status.color)
                        }
                    }
                    Button("Eliminar saga") {
                        plugin.removeSaga(id: progress.saga.id)
                    }
                }
            }
        }
        .navigationTitle("Sagas")
    }
}
#endif
