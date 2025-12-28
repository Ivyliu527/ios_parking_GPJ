//
//  ParkingListView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct ParkingListView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingReservationSheet = false
    @State private var selectedSpot: ParkingSpot?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search spots...", text: $parkingViewModel.searchText)
                            .onChange(of: parkingViewModel.searchText) { _ in
                                parkingViewModel.applyFilters()
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    HStack {
                        Toggle("Available Only", isOn: $parkingViewModel.showOnlyAvailable)
                            .onChange(of: parkingViewModel.showOnlyAvailable) { _ in
                                parkingViewModel.applyFilters()
                            }
                        
                        Spacer()
                        
                        Menu {
                            Button("All Floors") {
                                parkingViewModel.selectedFloor = nil
                                parkingViewModel.applyFilters()
                            }
                            ForEach(parkingViewModel.getFloors(), id: \.self) { floor in
                                Button("Floor \(floor)") {
                                    parkingViewModel.selectedFloor = floor
                                    parkingViewModel.applyFilters()
                                }
                            }
                        } label: {
                            HStack {
                                Text(parkingViewModel.selectedFloor == nil ? "All Floors" : "Floor \(parkingViewModel.selectedFloor!)")
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Parking Spots List
                if parkingViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if parkingViewModel.filteredSpots.isEmpty {
                    VStack {
                        Image(systemName: "car.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No parking spots found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(parkingViewModel.filteredSpots) { spot in
                        ParkingSpotRow(spot: spot) {
                            selectedSpot = spot
                            showingReservationSheet = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Parking Spots")
            .onAppear {
                parkingViewModel.loadParkingSpots()
            }
            .sheet(item: $selectedSpot) { spot in
                ReservationView(spot: spot)
                    .environmentObject(reservationViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct ParkingSpotRow: View {
    let spot: ParkingSpot
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(spot.number)
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", spot.pricePerHour))/hr")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Label("Floor \(spot.floor)", systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if !spot.features.isEmpty {
                            Text("•")
                                .foregroundColor(.gray)
                            ForEach(spot.features.prefix(2), id: \.self) { feature in
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: spot.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(spot.isAvailable ? .green : .red)
                        .font(.title2)
                    
                    Text(spot.isAvailable ? "Available" : "Occupied")
                        .font(.caption)
                        .foregroundColor(spot.isAvailable ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

