import SwiftUI

/// F3 Categorías en la biblioteca: el desplegable para filtrar los libros por categoría.
/// Recibe las categorías y un Binding a la selección (CategoryFilter.all o un uuidString).
struct CategoryFilterView: View {
    let categories: [Category]
    @Binding var selection: String

    var body: some View {
        Picker("Categoría", selection: $selection) {
            Text("Todas").tag(CategoryFilter.all)
            ForEach(categories) { category in
                Text(category.name).tag(category.id.uuidString)
            }
        }
    }
}
