//
//  BackgroundView.swift
//  Cinna
//
//  Created by Brighton Young on 11/10/25.
//


import SwiftUI

struct BackgroundView: View {
    var body: some View {
        GeometryReader { proxy in
            Image("RedCarpet")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .ignoresSafeArea()
        }
    }
}
