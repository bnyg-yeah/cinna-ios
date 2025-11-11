//
//  ContentView.swift
//  Cinna
//
//

import SwiftUI

struct ContentView: View {
    
    private enum Tab: Hashable {
        case theaters
        case home
        case user
    }
    
    @AppStorage("userHasCompletedLogin") private var userHasCompletedLogin: Bool = false
    
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        
        if userHasCompletedLogin {
            TabView(selection: $selectedTab) {
                Theaters()
                    .tabItem{
                        Label("Theaters", systemImage: "ticket")
                    }
                    .tag(Tab.theaters)
                
                Home()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(Tab.home)
                
                User()
                    .tabItem{
                        Label("User", systemImage: "person")
                    }
                    .tag(Tab.user)
                
            }
            
        } //end if userHasCompletedLogin
        else {
            LoginView {
                userHasCompletedLogin = true //uses onContinue in Login.swift
                //this should stay true for the rest of the time that the user has the app installed
            }
        }
    }
    
}

#Preview {
    ContentView()
        .environmentObject(UserInfoData())
        .environmentObject(MoviePreferencesData())
}
