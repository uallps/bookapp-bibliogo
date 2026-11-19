import SwiftUI

/// Pantalla de Ajustes: activa o desactiva las características en ejecución.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        Form {
            Section(header: Text("Características")) {
                Toggle("Mostrar autores", isOn: $config.showAuthors)
#if Progreso
                Toggle("Mostrar progreso de lectura", isOn: $config.showProgress)
#endif
                Toggle("Mostrar valoraciones", isOn: $config.showRatings)
            }
        }
        .navigationTitle("Ajustes")
    }
}
