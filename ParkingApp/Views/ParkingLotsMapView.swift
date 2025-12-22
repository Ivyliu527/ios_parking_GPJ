//
//  ParkingLotsMapView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import MapKit
import CoreLocation

/// 停车场地图视图
struct ParkingLotsMapView: View {
    @EnvironmentObject var parkingLotViewModel: ParkingLotViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLot: ParkingLot?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: parkingLotViewModel.filtered) { lot in
                    MapAnnotation(coordinate: lot.coordinate) {
                        Button(action: {
                            selectedLot = lot
                            showingDetail = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(lotColor(for: lot))
                                    .font(.title)
                                
                                VStack(spacing: 2) {
                                    Text(lot.name.prefix(6))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    
                                    Text(lot.availabilityText)
                                        .font(.caption2)
                                }
                                .padding(4)
                                .background(lotColor(for: lot).opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .onAppear {
                    parkingLotViewModel.loadLots()
                    locationManager.request()
                }
                .onChange(of: locationManager.currentLocation) { newLocation in
                    if let location = newLocation {
                        region.center = location.coordinate
                        parkingLotViewModel.updateCurrentLocation(location)
                    }
                }
//                .onChange(of: parkingLotViewModel.filtered) { _ in
//                    updateRegionIfNeeded()
//                }
                .onChange(of: parkingLotViewModel.filtered.map { $0.id }.joined(separator: "|")) { _ in
                updateRegionIfNeeded()
                }
                
                VStack {
                    // 定位授权提示
                    if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        LocationPermissionAlert()
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(NSLocalizedString("parking_map_title"))
            .sheet(isPresented: $showingDetail) {
                if let lot = selectedLot {
                    ParkingLotDetailView(lot: lot, currentLocation: locationManager.currentLocation)
                }
            }
        }
    }
    
    /// 根据停车场状态返回颜色
    private func lotColor(for lot: ParkingLot) -> Color {
        if let hasAvailable = lot.hasAvailableSpaces {
            return hasAvailable ? .green : .red
        }
        return .gray
    }
    
    /// 更新地图区域（如果需要）
    private func updateRegionIfNeeded() {
        guard !parkingLotViewModel.filtered.isEmpty else { return }
        
        // 如果有当前位置，以当前位置为中心
        if let location = locationManager.currentLocation {
            region.center = location.coordinate
        } else if let firstLot = parkingLotViewModel.filtered.first {
            region.center = firstLot.coordinate
        }
    }
}

