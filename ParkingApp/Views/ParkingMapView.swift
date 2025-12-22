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
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedSpot: ParkingSpot?
    @State private var showingReservationSheet = false
    
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
                    
                    if let activeReservation = reservationViewModel.activeReservation,
                       let spot = parkingService.getSpotById(activeReservation.parkingSpotId) {
                        ActiveReservationCard(reservation: activeReservation, spot: spot)
                            .padding()
                    }
                }
            }
            .navigationTitle("Parking Map")
            .sheet(item: $selectedSpot) { spot in
                ReservationView(spot: spot)
                    .environmentObject(reservationViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private var parkingService: ParkingService {
        ParkingService.shared
    }
}

struct ActiveReservationCard: View {
    let reservation: Reservation
    let spot: ParkingSpot
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Active Reservation")
                        .font(.headline)
                    Text("Spot: \(spot.number)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    reservationViewModel.completeReservation(reservation)
                }) {
                    Text("End")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Time Remaining")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatTime(timeRemaining))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", reservation.totalCost))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .onAppear {
            updateTimeRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateTimeRemaining() {
        if let remaining = reservationViewModel.calculateRemainingTime(reservation) {
            timeRemaining = remaining
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

/// 定位权限被拒绝时的提示视图
struct LocationPermissionAlert: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(NSLocalizedString("location_permission_denied"))
                .font(.headline)
            
            Text(NSLocalizedString("location_permission_message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text(NSLocalizedString("go_to_settings"))
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

