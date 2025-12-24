//
//  ParkingLotsListView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import CoreLocation

/// 停车场列表视图
struct ParkingLotsListView: View {
    @EnvironmentObject var parkingLotViewModel: ParkingLotViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLot: ParkingLot?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(NSLocalizedString("search_placeholder"), text: $parkingLotViewModel.searchText)
                        .onChange(of: parkingLotViewModel.searchText) { _ in
                            parkingLotViewModel.onSearchTextChanged()
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // 筛选和排序 UI（任务5）
                FilterAndSortView()
                    .environmentObject(parkingLotViewModel)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // 停车场列表
                if parkingLotViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if parkingLotViewModel.filtered.isEmpty {
                    VStack {
                        Image(systemName: "parkinglot")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(NSLocalizedString("no_results"))
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(parkingLotViewModel.filtered) { lot in
                        ParkingLotRow(
                            lot: lot,
                            currentLocation: locationManager.currentLocation
                        ) {
                            selectedLot = lot
                            showingDetail = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(NSLocalizedString("parking_list_title"))
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
                }
            }
        }
    }
}

// ParkingLotsListView.swift 中的 ParkingLotRow 結構
struct ParkingLotRow: View {
    let lot: ParkingLot
    let currentLocation: CLLocation?
    let onTap: () -> Void
    
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingFavoriteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(lot.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // 收藏愛心圖標
                            if authViewModel.isFavorite(parkingLotId: lot.id) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(lot.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(lot.availabilityText)
                            .font(.headline)
                            .foregroundColor(availabilityColor)
                        
                        if let distance = distanceText {
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    // 设施图标
                    if lot.facilities?.evChargers?.count ?? 0 > 0 {
                        Label("EV", systemImage: "bolt.car.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if lot.facilities?.covered == true {
                        Label(NSLocalizedString("covered_filter"), systemImage: "house.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if lot.facilities?.cctv == true {
                        Label("CCTV", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let priceRules = lot.priceRules, priceRules != "暂未提供" {
                        Text(priceRules)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            // 右鍵/長按菜單
            Button {
                toggleFavorite()
            } label: {
                Label(
                    authViewModel.isFavorite(parkingLotId: lot.id) ?
                    "Remove from Favorites" : "Add to Favorites",
                    systemImage: authViewModel.isFavorite(parkingLotId: lot.id) ?
                    "heart.slash" : "heart"
                )
            }
            
            Button {
                shareParkingLot()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .onLongPressGesture {
            showingFavoriteAlert = true
        }
        .alert("Favorite", isPresented: $showingFavoriteAlert) {
            Button("Cancel", role: .cancel) { }
            Button(authViewModel.isFavorite(parkingLotId: lot.id) ?
                   "Remove from Favorites" : "Add to Favorites") {
                toggleFavorite()
            }
        } message: {
            Text(authViewModel.isFavorite(parkingLotId: lot.id) ?
                 "Remove \(lot.name) from favorites?" :
                 "Add \(lot.name) to favorites?")
        }
    }
    
    private var availabilityColor: Color {
        if let hasAvailable = lot.hasAvailableSpaces {
            return hasAvailable ? .green : .red
        }
        return .gray
    }
    
    private var distanceText: String? {
        guard let location = currentLocation else { return nil }
        let distance = location.distance(from: lot.location)
        if distance < 1000 {
            return String(format: "%.0f%@", distance, NSLocalizedString("meters"))
        } else {
            return String(format: "%.1f%@", distance / 1000, NSLocalizedString("kilometers"))
        }
    }
    
    private func toggleFavorite() {
        guard authViewModel.isAuthenticated else {
            // 如果未登入，可以提示登入
            showingFavoriteAlert = true
            return
        }
        
        authViewModel.toggleFavorite(parkingLotId: lot.id)
    }
    
    private func shareParkingLot() {
        let shareText = "Check out \(lot.name) at \(lot.address)"
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // 在 iOS 中顯示分享面板
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// 筛选和排序视图（任务5）
struct FilterAndSortView: View {
    @EnvironmentObject var viewModel: ParkingLotViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // 筛选开关
            HStack(spacing: 16) {
                Toggle(NSLocalizedString("only_available"), isOn: Binding(
                    get: { viewModel.filters.onlyAvailable },
                    set: { newValue in
                        viewModel.filters.onlyAvailable = newValue
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                ))
                .font(.caption)
                
                Toggle(NSLocalizedString("ev_charging_filter"), isOn: Binding(
                    get: { viewModel.filters.hasEV },
                    set: { newValue in
                        viewModel.filters.hasEV = newValue
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                ))
                .font(.caption)
                
                Toggle(NSLocalizedString("covered_filter"), isOn: Binding(
                    get: { viewModel.filters.covered },
                    set: { newValue in
                        viewModel.filters.covered = newValue
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                ))
                .font(.caption)
                
                Toggle("CCTV", isOn: Binding(
                    get: { viewModel.filters.cctv },
                    set: { newValue in
                        viewModel.filters.cctv = newValue
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                ))
                .font(.caption)
            }
            
            // 排序菜单
            HStack {
                Text(NSLocalizedString("sort_by") + ":")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Menu {
                    Button(NSLocalizedString("sort_distance")) {
                        viewModel.sortBy = .distance
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                    
                    Button(NSLocalizedString("sort_vacancies")) {
                        viewModel.sortBy = .vacancies
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                    
                    Button(NSLocalizedString("sort_price")) {
                        viewModel.sortBy = .priceHint
                        viewModel.applyFiltersAndSort(currentLocation: nil)
                    }
                } label: {
                    HStack {
                        Text(sortByText)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var sortByText: String {
        switch viewModel.sortBy {
        case .distance: return NSLocalizedString("sort_distance")
        case .vacancies: return NSLocalizedString("sort_vacancies")
        case .priceHint: return NSLocalizedString("sort_price")
        }
    }
}

