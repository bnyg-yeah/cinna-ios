////
////  LoginButtonStyle.swift
////  Cinna
////
////  Created by Brighton Young on 10/10/25.
////
//
//import SwiftUI
//
//struct LoginPrimaryButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.headline)
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 16)
//            .background(backgroundColor(for: configuration))
//            .foregroundColor(.white)
//            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//            .shadow(color: Color(.systemIndigo).opacity(configuration.isPressed ? 0.1 : 0.25), radius: 12, y: 6)
//            .scaleEffect(configuration.isPressed ? 0.97 : 1)
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//            .padding(.horizontal)
//    }
//
//    private func backgroundColor(for configuration: Configuration) -> Color {
//        configuration.isPressed ? Color.accentColor.opacity(0.85) : Color.accentColor
//    }
//}
//
//extension ButtonStyle where Self == LoginPrimaryButtonStyle {
//    static var loginPrimary: LoginPrimaryButtonStyle { LoginPrimaryButtonStyle() }
//}
