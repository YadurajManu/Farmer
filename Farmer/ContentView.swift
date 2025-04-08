//
//  ContentView.swift
//  Farmer
//
//  Created by Yaduraj Singh on 08/04/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.authState == .signedIn {
                MainTabViewAuth()
                    .environmentObject(authManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Ensure auth state is up to date
            authManager.checkAuthState()
        }
    }
}

#Preview {
    ContentView()
}
