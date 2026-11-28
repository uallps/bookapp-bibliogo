#if Sugerencia
import SwiftUI

/// O1 Sugerencia de próxima lectura: propone un libro pendiente según la estrategia XOR activa
/// (aleatoria o por tiempo y extensión).
struct NextReadingSuggestionView: View {
    var plugin: SuggestionPlugin
    @Environment(AppConfig.self) private var config

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private var availableTimeBinding: Binding<AvailableTime> {
        Binding(
            get: { plugin.criteria.availableTime },
            set: { newValue in
                plugin.criteria.availableTime = newValue
                plugin.suggestNext(avoidCurrent: false)
            }
        )
    }

    private var preferredLengthBinding: Binding<PreferredLength> {
        Binding(
            get: { plugin.criteria.preferredLength },
            set: { newValue in
                plugin.criteria.preferredLength = newValue
                plugin.suggestNext(avoidCurrent: false)
            }
        )
    }

    private var availableTimeRawBinding: Binding<String> {
        Binding(
            get: { plugin.criteria.availableTime.rawValue },
            set: { newValue in
                if let parsed = AvailableTime(rawValue: newValue) {
                    plugin.criteria.availableTime = parsed
                    plugin.suggestNext(avoidCurrent: false)
                }
            }
        )
    }

    private var preferredLengthRawBinding: Binding<String> {
        Binding(
            get: { plugin.criteria.preferredLength.rawValue },
            set: { newValue in
                if let parsed = PreferredLength(rawValue: newValue) {
                    plugin.criteria.preferredLength = parsed
                    plugin.suggestNext(avoidCurrent: false)
                }
            }
        )
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleSuggestionBody
            .onAppear { plugin.ensureSuggestion() }
#else
        openUISuggestionBody
            .onAppear { plugin.ensureSuggestion() }
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleSuggestionBody: some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    editorialHeader

                    if plugin.usesTimeAndLength {
                        criteriaCard
                    }

                    if let suggestion = plugin.displayedSuggestion {
                        suggestionCard(suggestion)
                    } else {
                        emptyPendingCard
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
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("PRÓXIMA LECTURA · \(plugin.strategyName.uppercased())")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }

            Text("Sugerencia de Lectura")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Text(plugin.strategyDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var criteriaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TU MOMENTO DE LECTURA")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))

            VStack(alignment: .leading, spacing: 8) {
                Text("Tiempo disponible")
                    .font(.subheadline.weight(.semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AvailableTime.allCases) { option in
                            optionChip(
                                title: option.rawValue,
                                isSelected: plugin.criteria.availableTime == option
                            ) {
                                availableTimeBinding.wrappedValue = option
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Extensión preferida")
                    .font(.subheadline.weight(.semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PreferredLength.allCases) { option in
                            optionChip(
                                title: option.rawValue,
                                isSelected: plugin.criteria.preferredLength == option
                            ) {
                                preferredLengthBinding.wrappedValue = option
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private func optionChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                action()
            }
        } label: {
            Text(title)
                .font(.caption.weight(isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.bookSageForeground(for: colorScheme) : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.bookSageSurface(for: colorScheme) : Color.bookCard(for: colorScheme).opacity(0.7))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.bookAccentAdaptive(for: colorScheme).opacity(0.35) : Color.bookBorder(for: colorScheme),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func suggestionCard(_ suggestion: BookSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.bookSageSurface(for: colorScheme))
                        .frame(width: 52, height: 68)
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.book.title)
                        .font(.system(.title3, design: .serif).bold())
                        .foregroundColor(.primary)

                    if config.showAuthors, let author = suggestion.book.author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        if let pages = suggestion.totalPages {
                            badge(text: "\(pages) págs.", icon: "book.pages")
                        }
                        if let estimate = suggestion.estimatedReadingTime {
                            badge(text: estimate, icon: "clock")
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        plugin.suggestNext()
                    }
                } label: {
                    Label("Otra sugerencia", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.bookSageSurface(for: colorScheme))
                        )
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        plugin.startReading(suggestion.book)
                    }
                } label: {
                    Label("Empezar a leer", systemImage: "bookmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.bookAccent)
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 20)
    }

    private func badge(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(Color.bookSageForeground(for: colorScheme))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
    }

    private var emptyPendingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "books.vertical")
                    .font(.title2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("No tienes libros pendientes")
                    .font(.system(.headline, design: .serif))
            }
            Text("Añade un libro nuevo o marca alguno como Pendiente en tu Biblioteca para recibir una sugerencia.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 20)
    }
#endif

    private var openUISuggestionBody: some View {
        Form {
            if plugin.usesTimeAndLength {
                Section(header: Text("Tiempo y extensión")) {
                    Picker("Tiempo disponible", selection: availableTimeRawBinding) {
                        ForEach(AvailableTime.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    Picker("Extensión preferida", selection: preferredLengthRawBinding) {
                        ForEach(PreferredLength.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                }
            }

            Section(header: Text("Sugerencia (\(plugin.strategyName))")) {
                if let suggestion = plugin.displayedSuggestion {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(suggestion.book.title)
                            .font(.headline)
                        if config.showAuthors, let author = suggestion.book.author, !author.isEmpty {
                            Text(author)
                                .bookCaption()
                        }
                        if let pages = suggestion.totalPages {
                            Text("\(pages) páginas" + (suggestion.estimatedReadingTime.map { " · \($0)" } ?? ""))
                                .bookCaption()
                        }
                        Text(suggestion.reason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        Button("Otra sugerencia") {
                            plugin.suggestNext()
                        }
                        Button("Empezar a leer") {
                            plugin.startReading(suggestion.book)
                        }
                    }
                } else {
                    Text("No tienes libros pendientes en tu biblioteca.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Sugerencia")
    }
}
#endif
