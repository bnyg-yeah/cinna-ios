//
//  ReadyPage.swift
//  Cinna
//
//  Created by Brighton Young on 10/9/25.
//

import SwiftUI

struct ReadyView: View {
    var finish: () -> Void
    var name: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            Image("UserPicture")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("All Set, \(name.isEmpty ? "my Cinna" : name)!")
                    .font(.largeTitle).bold()

                Text("\(Text("Cinna").italic()) is now able to tirelessly find movies for you for free!")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                finish()
            } label: {
                Text("Go to Home")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.top, 20)
            Spacer()
        }
        .padding(.top, 48)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ReadyView(
        finish: {},
        name: ""
    )
}
