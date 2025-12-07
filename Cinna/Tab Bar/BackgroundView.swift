//
//  BackgroundView.swift
//  Cinna
//
//  Created by Brighton Young on 11/10/25.
//

import SwiftUI

struct BackgroundView: View {
    var body: some View {
        Image("RedCarpet")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.4).ignoresSafeArea())
    }
}
