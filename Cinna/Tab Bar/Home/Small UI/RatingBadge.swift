//
//  RatingBadge.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//


import SwiftUI

struct RatingBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemYellow).opacity(0.2))
            .foregroundStyle(Color(.systemOrange))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityLabel("Rating \(text)")
    }
}
