//
//  FavoritesView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import CoreLocation

struct FavoritesView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var parkingLotViewModel: ParkingLotViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLot: ParkingLot?
    @State private var showingDetail = false
    
    private var favoriteLots: [ParkingLot] {
        guard authViewModel.isAuthenticated else { return [] }
        let favoriteIds = authViewModel.getFavorites()
        return parkingLotViewModel.lots.filter { favoriteIds.contains($0.id) }
            .sorted { lot1, lot2 in
                // 按距离排序（如果有当前位置）
                if let location = locationManager.currentLocation {
                    let distance1 = location.distance(from: lot1.location)
                    let distance2 = location.distance(from: lot2.location)
                    return distance1 < distance2
                }
                return lot1.name < lot2.name
            }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !authViewModel.isAuthenticated {
                    // 未登录提示
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(NSLocalizedString("please_login"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("login_to_view_favorites"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favoriteLots.isEmpty {
                    // 空收藏列表
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(NSLocalizedString("no_favorites"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("add_favorites_hint"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 收藏列表
                    List {
                        // 离线模式提示
                        if !networkMonitor.isConnected {
                            Section {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString("offline_mode"))
                                            .font(.headline)
                                        Text(NSLocalizedString("network_unavailable"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        ForEach(favoriteLots) { lot in
                            ParkingLotRow(
                                lot: lot,
                                currentLocation: locationManager.currentLocation
                            ) {
                                selectedLot = lot
                                showingDetail = true
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(NSLocalizedString("favorites"))
            .onAppear {
                parkingLotViewModel.loadLots()
                locationManager.request()
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                parkingLotViewModel.updateCurrentLocation(newLocation)
            }
            .sheet(isPresented: $showingDetail) {
                if let lot = selectedLot {
                    ParkingLotDetailView(lot: lot, currentLocation: locationManager.currentLocation)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

