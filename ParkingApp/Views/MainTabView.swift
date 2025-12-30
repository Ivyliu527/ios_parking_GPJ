//
//  MainTabView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject private var languageManager = LanguageManager.shared
    @StateObject private var parkingViewModel = ParkingViewModel()
    @StateObject private var parkingLotViewModel = ParkingLotViewModel()
    
    var body: some View {
        TabView {
            // 停车场列表视图（首页）
            ParkingLotsListView()
                .environmentObject(parkingLotViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Label(NSLocalizedString("parking_list_title"), systemImage: "list.bullet")
                }
            
            // 停车场地图视图
            ParkingLotsMapView()
                .environmentObject(parkingLotViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Label(NSLocalizedString("parking_map_title"), systemImage: "map")
                }
            
            FavoritesView()
                .environmentObject(authViewModel)
                .environmentObject(parkingLotViewModel)
                .tabItem {
                    Label(NSLocalizedString("favorites"), systemImage: "heart")
                }
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label(NSLocalizedString("profile_title"), systemImage: "person")
                }
        }
    }
}

