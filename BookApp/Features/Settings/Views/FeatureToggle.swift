import SwiftUI

/// Un ajuste de Ajustes para encender o apagar una característica. Lo usan el núcleo
/// y los plugins, para que todos los ajustes se vean igual.
/// En Apple es una fila con icono y explicación; en Linux y Windows, un Toggle normal.
struct FeatureToggle: View {
    let title: String
    var subtitle: String = ""
    var systemImage: String = "switch.2"
    @Binding var isOn: Bool

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(Color.bookSageSurface(for: colorScheme))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 8)
#else
        Toggle(title, isOn: $isOn)
#endif
    }
}
