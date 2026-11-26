import SwiftUI

/// F3 Categorías en la biblioteca: píldoras horizontales en Apple (estilo prototipo BiblioGo)
/// y desplegable Picker en SwiftOpenUI.
struct CategoryFilterView: View {
    let categories: [Category]
    @Binding var selection: String

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "Todas", value: CategoryFilter.all)

                ForEach(categories) { category in
                    categoryChip(title: category.name, value: category.id.uuidString)
                }
            }
            .padding(.vertical, 2)
        }
#else
        Picker("Categoría", selection: $selection) {
            Text("Todas").tag(CategoryFilter.all)
            ForEach(categories) { category in
                Text(category.name).tag(category.id.uuidString)
            }
        }
#endif
    }

#if !canImport(SwiftOpenUI)
    private func categoryChip(title: String, value: String) -> some View {
        let isSelected = selection == value
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selection = value
            }
        } label: {
            Text(title)
                .font(.caption.weight(isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.bookSageForeground(for: colorScheme) : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
#endif
}
