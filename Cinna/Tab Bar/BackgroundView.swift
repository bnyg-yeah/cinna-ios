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
            ZStack {
                // Fallback color in case image doesn't load
                Color.red
                
                Image("RedCarpet")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                
                // Dark overlay to improve text readability
                Color.black.opacity(0.4)
            }
        }
        .ignoresSafeArea(.all) // Move this outside GeometryReader and use .all
    }
}
