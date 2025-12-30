//
//  ParkingMapView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import MapKit
import CoreLocation

struct ParkingMapView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedSpot: ParkingSpot?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: parkingViewModel.parkingSpots) { spot in
                    MapAnnotation(coordinate: spot.location.coordinate) {
                        Button(action: {
                            selectedSpot = spot
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(spot.isAvailable ? .green : .red)
                                    .font(.title)
                                Text(spot.number)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(spot.isAvailable ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    parkingViewModel.loadParkingSpots()
                    locationManager.request()
                }
                .onChange(of: locationManager.currentLocation) { newLocation in
                    if let location = newLocation {
                        region.center = location.coordinate
                    }
                }
                
                VStack {
                    // 定位授权被拒绝时的提示
                    if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        LocationPermissionAlert()
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Parking Map")
        }
    }
}


/// 定位权限被拒绝时的提示视图
struct LocationPermissionAlert: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Location Access Required")
                .font(.headline)
            
            Text("Please enable location services in Settings to find nearby parking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text("Go to Settings")
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

