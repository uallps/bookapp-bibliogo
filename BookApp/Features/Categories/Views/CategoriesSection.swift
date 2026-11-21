import SwiftUI

/// F3 Categorías en el detalle: un interruptor por categoría para clasificar el libro,
/// y un campo para crear categorías nuevas. Recibe valores y Binding, no el plugin.
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

    var body: some View {
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
