//
//  MovieTickets.swift
//  Cinna
//
//  Created by Brighton Young on 10/4/25.
//

import SwiftUI

struct MovieTickets: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Movie Tickets")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Purchase history, upcoming showings, and ticket management will live here.")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(BackgroundView())
        .navigationTitle("Movie Tickets")
        .navigationBarTitleDisplayMode(.inline)
    }
}
