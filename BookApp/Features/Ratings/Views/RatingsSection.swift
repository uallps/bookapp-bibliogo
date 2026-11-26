import SwiftUI

/// F4 Valoraciones y reseñas: sección del detalle que muestra las valoraciones
/// de otros usuarios y permite al usuario añadir la suya propia.
struct RatingsSection: View {
    @Binding var reviews: [BookReview]
    let bookID: UUID

    @State private var newRating: Int = 5
    @State private var newUserName: String = ""
    @State private var newComment: String = ""

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleRatingsCard
#else
        openUIRatingsSection
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleRatingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Valoraciones y reseñas", systemImage: "star.bubble")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                if !reviews.isEmpty {
                    Text("\(reviews.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                }
            }

            if !reviews.isEmpty {
                appleAverageBanner
            } else {
                Text("Aún no hay valoraciones para este libro. ¡Sé el primero en compartir tu impresión!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !reviews.isEmpty {
                VStack(spacing: 10) {
                    ForEach(reviews) { review in
                        AppleReviewCard(review: review) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                reviews.removeAll { $0.id == review.id }
                            }
                        }
                    }
                }
            }

            appleNewReviewComposer
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private var appleAverageBanner: some View {
        let total = reviews.reduce(0) { $0 + $1.rating }
        let average = Double(total) / Double(reviews.count)

        return HStack(spacing: 14) {
            Text(String(format: "%.1f", average))
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 4) {
                StaticStarRatingView(rating: Int(average.rounded()))
                Text("\(reviews.count) \(reviews.count == 1 ? "valoración de lectores" : "valoraciones de lectores")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bookStarSurface(for: colorScheme))
        )
    }

    private var appleNewReviewComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Añadir tu valoración")
                .font(.system(.subheadline, design: .serif).bold())

            HStack {
                Text("Tu puntuación")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                StarRatingView(rating: $newRating)
            }

            TextField("Tu nombre (opcional)", text: $newUserName)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bookCard(for: colorScheme))
                )

            TextField("Escribe tu opinión o reseña…", text: $newComment, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(3...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bookCard(for: colorScheme))
                )

            Button(action: addReview) {
                HStack(spacing: 8) {
                    Image(systemName: "star.bubble.fill")
                    Text("Publicar valoración")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.bookAccent)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bookBackground(for: colorScheme))
        )
    }
#endif

    private var openUIRatingsSection: some View {
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

    // MARK: - Subvistas SwiftOpenUI

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
                .foregroundColor(.bookStar)
                .font(.title3)
            Text(String(format: "%.1f de 5", average))
                .font(.headline)
            Spacer()
            Text("\(reviews.count) \(reviews.count == 1 ? "valoración" : "valoraciones")")
                .bookCaption()
        }
        .padding(.vertical, 4)
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

#if !canImport(SwiftOpenUI)
private struct AppleReviewCard: View {
    let review: BookReview
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(review.isUserReview ? Color.bookAccent : Color.bookSageSurface(for: colorScheme))
                        .frame(width: 30, height: 30)
                    Text(String(review.userName.prefix(1)).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(review.isUserReview ? .white : Color.bookSageForeground(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(review.userName)
                            .font(.subheadline.weight(.semibold))
                        if review.isUserReview {
                            Text("Tú")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(Color.bookSageForeground(for: colorScheme))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                        }
                    }
                    StaticStarRatingView(rating: review.rating)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dateString(review.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if review.isUserReview {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.bookBackground(for: colorScheme))
        )
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
#endif

/// Fila que muestra una valoración individual (SwiftOpenUI).
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
                        .bookCaption(color: Color.bookAccent)
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
