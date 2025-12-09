//
//  WelcomePage.swift
//  Cinna
//
//  Created by Brighton Young on 10/9/25.
//
import SwiftUI
import AVFoundation

struct WelcomeView: View {
    var next: () -> Void
    
    @State private var whipSound: AVAudioPlayer?
    @State private var screamSound: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: 24) {
            Image("CinnaIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 280)
                .foregroundColor(.accentColor)
            
            Text("Welcome to \(Text("Cinna").italic())")
                .font(.largeTitle).bold()
            
            Text("Your AI-powered movie servant, ready to tailor reviews, recommend films, and even blend you into a movie scene.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                playWhipAndScreamSound()
                next()
            } label: {
                Text("Let's Work!")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.top, 24)
            
        }
        .padding()
    }
    
    private func playWhipAndScreamSound() {
        guard
            let whipURL = Bundle.main.url(forResource: "whipSound", withExtension: "mp3"),
            let screamURL = Bundle.main.url(forResource: "screamSound", withExtension: "mp3")
        else {
            print("⚠️ Missing audio file(s).")
            return
        }
        
        do {
            whipSound = try AVAudioPlayer(contentsOf: whipURL)
            screamSound = try AVAudioPlayer(contentsOf: screamURL)
            
            whipSound?.delegate = AVPlayerDelegate.shared
            AVPlayerDelegate.shared.onFinish = { _ in
                screamSound?.play()  // play when whip finishes
            }
            
            whipSound?.prepareToPlay()
            screamSound?.prepareToPlay()
            whipSound?.play()
        } catch {
            print("⚠️ Error loading sounds: \(error.localizedDescription)")
        }
    }
}

class AVPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AVPlayerDelegate()
    var onFinish: ((AVAudioPlayer) -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?(player)
    }
}
#Preview {
    WelcomeView{}
}
