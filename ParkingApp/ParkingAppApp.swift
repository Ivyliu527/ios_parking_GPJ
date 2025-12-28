//
//  ParkingAppApp.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

@main
struct ParkingAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

