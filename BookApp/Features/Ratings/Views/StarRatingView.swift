import SwiftUI

/// Vista interactiva para seleccionar una puntuación de 1 a 5 estrellas.
struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(star <= rating ? .orange : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Vista no interactiva para mostrar estrellas fijas (por ejemplo en una reseña existente).
struct StaticStarRatingView: View {
    let rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .orange : .secondary)
                    .font(.caption)
            }
        }
    }
}

