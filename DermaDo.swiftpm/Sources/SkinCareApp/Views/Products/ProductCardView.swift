import SwiftUI

// MARK: - ProductCardView
struct ProductCardView: View {
    @EnvironmentObject var dependencies: AppDependencies
    let product: Product
    let matchedRoutines: [Routine]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Category Icon or Product Image
            ZStack {
                if let fileName = product.imageFileName,
                   let data = dependencies.productManager.fetchProductImage(named: fileName),
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appAccentSubtle, lineWidth: 1))
                } else {
                    Circle()
                        .fill(Color.appAccentSubtle)
                        .frame(width: 44, height: 44)

                    Image(systemName: product.category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.appAccentPrimary)
                }
            }

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.appHeading3)
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)

                if !product.brand.isEmpty {
                    Text(product.brand)
                        .font(.appCaptionText)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }

                // Routine Match Badges
                if !matchedRoutines.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(matchedRoutines) { routine in
                                HStack(spacing: 4) {
                                    Image(systemName: routine.timeOfDay == .morning ? "sun.max" : routine.timeOfDay == .evening ? "moon.stars" : "clock")
                                        .font(.system(size: 9))
                                        .symbolRenderingMode(.hierarchical)
                                    Text(routine.name)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.appAccentSubtle)
                                .foregroundColor(.appAccentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusFull, style: .continuous))
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Expiry indicator
            if product.isExpired {
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.appWarning)
                    .font(.system(size: 14))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextTertiary)
        }
        .padding(.vertical, 6)
    }
}
