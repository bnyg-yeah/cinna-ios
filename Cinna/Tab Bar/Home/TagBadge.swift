//
//  TagBadge.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//


import SwiftUI

struct TagBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill))
            .foregroundStyle(Color(.secondaryLabel))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(text)
    }
}
