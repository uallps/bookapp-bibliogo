#if Sagas
import SwiftUI

/// O6 Sagas en el detalle de un libro: elegir su saga (o ninguna), crear una nueva y
/// cambiar su número de orden con los botones − y +. Recibe valores y Binding, no el plugin.
struct SagaSection: View {
    /// Todas las sagas, para el Picker.
    let sagas: [Saga]
    /// "ninguna" o el uuidString de la saga del libro.
    @Binding var selection: String
    /// Su número dentro de la saga, si está en una.
    let order: Int?
    /// Cuántos libros tiene su saga.
    let count: Int
    /// Crea una saga con ese nombre y mete en ella el libro.
    let onCreate: (String) -> Void
    /// Mueve el libro: -1 antes, +1 después.
    let onMove: (Int) -> Void

    @State private var newName = ""

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    /// Por ejemplo, "nº 2 de 3".
    private var orderText: String {
        guard let order else { return "" }
        return "nº " + String(order) + " de " + String(count)
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleBody
#else
        openUIBody
#endif
    }

#if !canImport(SwiftOpenUI)
    // MARK: - Apple

    private var appleBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Saga", systemImage: Saga.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                if order != nil {
                    Text(verbatim: orderText)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                }
            }

            HStack(spacing: 10) {
                Picker("Saga", selection: $selection) {
                    Text("Ninguna").tag(SagaPlugin.noSaga)
                    ForEach(sagas) { saga in
                        Text(verbatim: saga.name).tag(saga.id.uuidString)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 280, alignment: .leading)

                Spacer(minLength: 0)

                if let order {
                    appleOrderButton(systemImage: "minus", enabled: order > 1) { onMove(-1) }
                    Text(verbatim: String(order))
                        .font(.system(.headline, design: .serif))
                        .frame(minWidth: 22)
                    appleOrderButton(systemImage: "plus", enabled: order < count) { onMove(1) }
                }
            }

            HStack(spacing: 10) {
                TextField("Nueva saga…", text: $newName)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.bookBackground(for: colorScheme))
                    )
                    .onSubmit(create)

                Button(action: create) {
                    Label("Crear saga", systemImage: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.bookAccent)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private func appleOrderButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.bookSageSurface(for: colorScheme)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .help(systemImage == "minus" ? "Leer antes" : "Leer después")
    }
#endif

    // MARK: - Linux y Windows

    private var openUIBody: some View {
        Section(header: Text("Saga")) {
            Picker("Saga", selection: $selection) {
                Text("Ninguna").tag(SagaPlugin.noSaga)
                ForEach(sagas) { saga in
                    Text(saga.name).tag(saga.id.uuidString)
                }
            }
            if order != nil {
                HStack(spacing: 12) {
                    Button("−") { onMove(-1) }
                    Text(orderText)
                    Button("+") { onMove(1) }
                }
            }
            TextField("Nueva saga", text: $newName)
            Button(action: create) {
                Label("Crear saga", systemImage: "plus.circle")
            }
        }
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        onCreate(name)
        newName = ""
    }
}
#endif
