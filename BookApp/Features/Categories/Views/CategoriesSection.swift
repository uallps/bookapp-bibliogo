import SwiftUI

/// F3 Categorías en el detalle: selección por categoría para clasificar el libro
/// y campo para crear categorías nuevas. Recibe valores y Binding, no el plugin.
struct CategoriesSection: View {
    /// Todas las categorías de la biblioteca. Es un Binding (solo se lee) para que una
    /// categoría recién creada aparezca al momento sin salir del detalle.
    @Binding var allCategories: [Category]
    /// Ids de las categorías de este libro.
    @Binding var selected: [UUID]
    /// Crea una categoría con ese nombre y se la pone a este libro.
    let onCreate: (String) -> Void
    /// Borra una categoría de la biblioteca (menú contextual). nil: no se puede borrar.
    var onDelete: ((UUID) -> Void)? = nil

    @State private var newName = ""

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleCategoriesCard
#else
        openUICategoriesSection
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Categorías", systemImage: Category.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                if !selected.isEmpty {
                    Text("\(selected.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                }
            }

            if allCategories.isEmpty {
                Text("Aún no hay categorías: crea la primera aquí debajo.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let columns = [GridItem(.adaptive(minimum: 115), spacing: 8)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(allCategories) { category in
                        let active = selected.contains(category.id)
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                toggleCategory(category)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: active ? "checkmark.circle.fill" : "tag")
                                    .font(.caption2)
                                Text(category.name)
                                    .font(.caption.weight(active ? .semibold : .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundColor(active ? .white : Color.bookSageForeground(for: colorScheme))
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(active ? Color.bookAccent : Color.bookSageSurface(for: colorScheme))
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let onDelete {
                                Button(role: .destructive) {
                                    onDelete(category.id)
                                } label: {
                                    Label("Eliminar categoría", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Nueva categoría…", text: $newName)
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
                    Label("Añadir", systemImage: Category.addSystemImage)
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

    private func toggleCategory(_ category: Category) {
        if selected.contains(category.id) {
            selected.removeAll { $0 == category.id }
        } else {
            selected.append(category.id)
        }
    }
#endif

    private var openUICategoriesSection: some View {
        Section(header: header) {
            if allCategories.isEmpty {
                Text("Aún no hay categorías: crea la primera aquí debajo.")
                    .bookCaption()
            }
            ForEach(allCategories) { category in
                Toggle(category.name, isOn: isSelected(category))
                    .contextMenu {
                        if let onDelete {
                            Button("Eliminar categoría") {
                                onDelete(category.id)
                            }
                        }
                    }
            }
            TextField("Nueva categoría", text: $newName)
            Button(action: create) {
                Label("Añadir categoría", systemImage: Category.addSystemImage)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Categorías")
            Spacer()
            if !selected.isEmpty {
                Text("\(selected.count)")
                    .bookCaption()
            }
        }
    }

    /// Encender el interruptor pone la categoría al libro; apagarlo se la quita.
    private func isSelected(_ category: Category) -> Binding<Bool> {
        Binding(
            get: { selected.contains(category.id) },
            set: { isOn in
                if isOn {
                    if !selected.contains(category.id) { selected.append(category.id) }
                } else {
                    selected.removeAll { $0 == category.id }
                }
            }
        )
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        onCreate(name)
        newName = ""
    }
}
