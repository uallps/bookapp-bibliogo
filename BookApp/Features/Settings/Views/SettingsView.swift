import SwiftUI

/// Pantalla de Ajustes: activa o desactiva las características en ejecución.
/// Debajo de los ajustes del núcleo van los de los plugins, sin saber de quién son.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleSettingsBody
#else
        openUISettingsBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleSettingsBody: some View {
        @Bindable var config = config
        return ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)
                                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                            Text("PREFERENCIAS")
                                .font(.caption2.weight(.bold))
                                .tracking(1.3)
                                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                        }

                        Text("Ajustes")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.primary)

                        Text("Personaliza qué detalles aparecen en tu biblioteca.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 0) {
                        FeatureToggle(
                            title: "Mostrar autores",
                            subtitle: "Ver el nombre del autor debajo del título",
                            systemImage: "person.text.rectangle",
                            isOn: $config.showAuthors
                        )

                        Divider().padding(.leading, 48)
                        FeatureToggle(
                            title: "Mostrar progreso de lectura",
                            subtitle: "Mostrar barra de avance y páginas leídas",
                            systemImage: "book.pages",
                            isOn: $config.showProgress
                        )

                        Divider().padding(.leading, 48)
                        FeatureToggle(
                            title: "Mostrar valoraciones",
                            subtitle: "Ver estrellas y nota media en cada libro",
                            systemImage: "star.fill",
                            isOn: $config.showRatings
                        )

                        // Los ajustes de los plugins, también de los apagados.
                        ForEach(PluginRegistry.shared.settingsViews()) { pluginView in
                            Divider().padding(.leading, 48)
                            pluginView.view
                        }
                    }
                    .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 16)

                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.bookAccent)
                                .frame(width: 38, height: 38)
                            Image(systemName: "book.pages.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BiblioGo")
                                .font(.system(.subheadline, design: .serif).bold())
                            Text("Tu espacio de lectura consciente")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 14)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 680)
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

#endif

    private var openUISettingsBody: some View {
        @Bindable var config = config
        return Form {
            Section(header: Text("Características")) {
                Toggle("Mostrar autores", isOn: $config.showAuthors)
                Toggle("Mostrar progreso de lectura", isOn: $config.showProgress)
                Toggle("Mostrar valoraciones", isOn: $config.showRatings)
                // Los ajustes de los plugins, también de los apagados.
                ForEach(PluginRegistry.shared.settingsViews()) { pluginView in
                    pluginView.view
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}
