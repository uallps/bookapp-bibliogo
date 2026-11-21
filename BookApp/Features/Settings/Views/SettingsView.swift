import SwiftUI

/// Pantalla de Ajustes: activa o desactiva las características en ejecución.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        Form {
            Section(header: Text("Características")) {
                Toggle("Mostrar autores", isOn: $config.showAuthors)
                Toggle("Mostrar progreso de lectura", isOn: $config.showProgress)
                Toggle("Mostrar valoraciones", isOn: $config.showRatings)
                Toggle("Mostrar categorías", isOn: $config.showCategories)
            }
        }
        .navigationTitle("Ajustes")
    }
}
