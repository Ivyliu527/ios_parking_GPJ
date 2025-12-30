//
//  ParkingLotDetailView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import MapKit
import CoreLocation

/// 停车场详情页
struct ParkingLotDetailView: View {
    let lot: ParkingLot
    let currentLocation: CLLocation?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingNavigationOptions = false
    @State private var showingLoginAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lot.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(lot.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let distance = distanceText {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(distance)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 空位信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("availability"))
                            .font(.headline)
                        
                        HStack {
                            Text(NSLocalizedString("available_total") + ":")
                                .foregroundColor(.secondary)
                            Text(lot.availabilityText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(availabilityColor)
                        }
                        
                        if lot.availableSpaces == nil {
                            Text(NSLocalizedString("unknown"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 营业时间
                    if let hours = lot.openingHours {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("opening_hours"))
                                .font(.headline)
                            Text(hours)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 收费规则
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("price_rules"))
                            .font(.headline)
                        Text(lot.priceRules ?? NSLocalizedString("not_provided"))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 设施信息
                    if let facilities = lot.facilities {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("facilities"))
                                .font(.headline)
                            
                            if let evChargers = facilities.evChargers {
                                HStack {
                                    Image(systemName: "bolt.car.fill")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString("ev_charging"))
                                            .fontWeight(.medium)
                                        if let count = evChargers.count {
                                            Text("\(NSLocalizedString("count")): \(count)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if let types = evChargers.types, !types.isEmpty {
                                            Text("\(NSLocalizedString("types")): \(types.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            if facilities.covered == true {
                                HStack {
                                    Image(systemName: "house.fill")
                                    Text(NSLocalizedString("covered"))
                                }
                            }
                            
                            if facilities.cctv == true {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text(NSLocalizedString("cctv"))
                                }
                            }
                            
                            if let phone = facilities.contactPhone {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(phone)
                                }
                                .onTapGesture {
                                    if let url = URL(string: "tel://\(phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 收藏按钮
                    VStack(spacing: 12) {
                        Button(action: {
                            if authViewModel.isAuthenticated {
                                authViewModel.toggleFavorite(parkingLotId: lot.id)
                            } else {
                                showingLoginAlert = true
                            }
                        }) {
                            HStack {
                                Image(systemName: authViewModel.isFavorite(parkingLotId: lot.id) ? "heart.fill" : "heart")
                                Text(authViewModel.isFavorite(parkingLotId: lot.id) ? 
                                     NSLocalizedString("remove_from_favorites") : 
                                     NSLocalizedString("add_to_favorites"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(authViewModel.isFavorite(parkingLotId: lot.id) ? Color.red.opacity(0.1) : Color(.systemGray5))
                            .foregroundColor(authViewModel.isFavorite(parkingLotId: lot.id) ? .red : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(authViewModel.isFavorite(parkingLotId: lot.id) ? Color.red : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.top)
                    
                    // 导航按钮
                    VStack(spacing: 12) {
                        Button(action: {
                            openInAppleMaps()
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text(NSLocalizedString("open_apple_maps"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        
                        if currentLocation != nil {
                            Button(action: {
                                showingNavigationOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(NSLocalizedString("built_in_route"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("parking_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNavigationOptions) {
                MapRouteView(
                    source: currentLocation!,
                    destination: lot.location,
                    destinationName: lot.name
                )
            }
            .alert(NSLocalizedString("please_login"), isPresented: $showingLoginAlert) {
                Button(NSLocalizedString("done"), role: .cancel) { }
            }
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
            return "\(NSLocalizedString("distance")): \(String(format: "%.0f", distance))\(NSLocalizedString("meters"))"
        } else {
            return "\(NSLocalizedString("distance")): \(String(format: "%.1f", distance / 1000))\(NSLocalizedString("kilometers"))"
        }
    }
    
    /// 打开 Apple 地图导航
    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: lot.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = lot.name
        
        let options: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: options)
    }
}

/// 内置路线预览视图（任务7）
struct MapRouteView: View {
    let source: CLLocation
    let destination: CLLocation
    let destinationName: String
    @Environment(\.dismiss) var dismiss
    @State private var route: MKRoute?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView(NSLocalizedString("calculating_route"))
                } else if let route = route {
                    VStack {
                        // 路线信息
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(NSLocalizedString("estimated_time") + ":")
                                    .foregroundColor(.secondary)
                                Text(formatTime(route.expectedTravelTime))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text(NSLocalizedString("route_distance") + ":")
                                    .foregroundColor(.secondary)
                                Text(formatDistance(route.distance))
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        
                        // 地图预览（简化版，实际可以使用 UIViewRepresentable 包装 MKMapView）
                        Text(NSLocalizedString("built_in_route"))
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                    }
                } else if let error = errorMessage {
                    VStack {
                        Text(NSLocalizedString("route_not_found"))
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("built_in_route"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                calculateRoute()
            }
        }
    }
    
    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let route = response?.routes.first {
                    self.route = route
                } else {
                    errorMessage = NSLocalizedString("route_not_found")
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        if hours > 0 {
            return "\(hours)\(NSLocalizedString("estimated_time"))\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f%@", distance, NSLocalizedString("meters"))
        } else {
            return String(format: "%.1f%@", distance / 1000, NSLocalizedString("kilometers"))
        }
    }
}


