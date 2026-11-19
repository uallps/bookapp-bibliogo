import SwiftUI

/// F4 Valoraciones y reseñas: sección del detalle que muestra las valoraciones
/// de otros usuarios y permite al usuario añadir la suya propia.
struct RatingsSection: View {
    @Binding var reviews: [BookReview]
    let bookID: UUID

    @State private var newRating: Int = 5
    @State private var newUserName: String = ""
    @State private var newComment: String = ""

    var body: some View {
        Section(header: ratingsHeader) {
            if !reviews.isEmpty {
                averageRatingView
            } else {
                Text("Aún no hay valoraciones para este libro. ¡Sé el primero en valorarlo!")
                    .bookCaption()
            }

            ForEach($reviews) { $review in
                ReviewRowView(review: review)
            }
            .onDelete { offsets in
                reviews.remove(atOffsets: offsets)
            }

            newReviewForm
        }
    }

    // MARK: - Subvistas

    private var ratingsHeader: some View {
        HStack {
            Text("Valoraciones y reseñas")
            Spacer()
            if !reviews.isEmpty {
                Text("\(reviews.count)")
                    .bookCaption()
            }
        }
    }

    private var averageRatingView: some View {
        let total = reviews.reduce(0) { $0 + $1.rating }
        let average = Double(total) / Double(reviews.count)

        return HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.orange)
            Text(String(format: "%.1f de 5", average))
                .font(.headline)
            Spacer()
            Text("(\(reviews.count) \(reviews.count == 1 ? "valoración" : "valoraciones"))")
                .bookCaption()
        }
        .padding(.vertical, 2)
    }

    private var newReviewForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Añadir tu valoración")
                .font(.subheadline)
                .bold()

            HStack {
                Text("Puntuación:")
                    .bookCaption()
                StarRatingView(rating: $newRating)
            }

            TextField("Tu nombre (opcional)", text: $newUserName)
                .bookCaption()

#if !canImport(SwiftOpenUI)
            TextField("Escribe tu opinión o reseña…", text: $newComment, axis: .vertical)
                .lineLimit(3...5)
#else
            TextField("Escribe tu opinión o reseña…", text: $newComment)
#endif

            Button(action: addReview) {
                Label("Publicar valoración", systemImage: "star.bubble")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Acciones

    private func addReview() {
        let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.isEmpty ? "Tú" : trimmedName
        let newReview = BookReview(
            bookID: bookID,
            userName: name,
            rating: newRating,
            comment: newComment.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Date(),
            isUserReview: true
        )
        reviews.append(newReview)

        // Limpiar formulario
        newComment = ""
        newRating = 5
    }
}

/// Fila que muestra una valoración individual (de otro usuario o del propio usuario).
private struct ReviewRowView: View {
    let review: BookReview

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(review.userName)
                    .font(.subheadline)
                    .bold()

                if review.isUserReview {
                    Text("(Tú)")
                        .bookCaption(color: .blue)
                }

                Spacer()

                Text(dateString(review.date))
                    .bookCaption()
            }

            StaticStarRatingView(rating: review.rating)

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

