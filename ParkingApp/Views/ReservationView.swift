//
//  ReservationView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct ReservationView: View {
    let spot: ParkingSpot
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedHours: Double = 1.0
    @State private var showingPayment = false
    @State private var reservation: Reservation?
    
    private var totalCost: Double {
        spot.pricePerHour * selectedHours
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Parking Spot Details")) {
                    HStack {
                        Text("Spot Number")
                        Spacer()
                        Text(spot.number)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Floor")
                        Spacer()
                        Text("\(spot.floor)")
                    }
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        Text("$\(String(format: "%.2f", spot.pricePerHour))/hour")
                            .foregroundColor(.blue)
                    }
                    
                    if !spot.features.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Features")
                            ForEach(spot.features, id: \.self) { feature in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(feature)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Reservation Duration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            Text("\(String(format: "%.1f", selectedHours))")
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $selectedHours, in: 0.5...24, step: 0.5)
                        
                        HStack {
                            Button("0.5h") { selectedHours = 0.5 }
                            Button("1h") { selectedHours = 1.0 }
                            Button("2h") { selectedHours = 2.0 }
                            Button("4h") { selectedHours = 4.0 }
                            Button("8h") { selectedHours = 8.0 }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
                
                Section(header: Text("Cost Summary")) {
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text("$\(String(format: "%.2f", totalCost))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button(action: {
                        if let user = authViewModel.currentUser {
                            let duration = selectedHours * 3600
                            reservation = reservationViewModel.createReservation(
                                spotId: spot.id,
                                userId: user.id,
                                duration: duration
                            )
                            showingPayment = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Reserve & Pay")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!spot.isAvailable)
                }
            }
            .navigationTitle("Reserve Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPayment) {
                if let reservation = reservation {
                    PaymentView(reservation: reservation)
                        .environmentObject(reservationViewModel)
                }
            }
        }
    }
}

