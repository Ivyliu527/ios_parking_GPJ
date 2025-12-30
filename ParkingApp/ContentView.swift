//
//  ContentView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

