//
//  ReservationHistoryView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct ReservationHistoryView: View {
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    private var userReservations: [Reservation] {
        guard let user = authViewModel.currentUser else { return [] }
        return reservationViewModel.getReservationsForUser(user.id)
            .sorted { $0.startTime > $1.startTime }
    }
    
    private var activeReservations: [Reservation] {
        userReservations.filter { $0.status == .active }
    }
    
    private var pastReservations: [Reservation] {
        userReservations.filter { $0.status != .active }
    }
    
    var body: some View {
        NavigationView {
            List {
                if !activeReservations.isEmpty {
                    Section(header: Text("Active Reservations")) {
                        ForEach(activeReservations) { reservation in
                            ReservationRow(reservation: reservation)
                        }
                    }
                }
                
                Section(header: Text("Past Reservations")) {
                    if pastReservations.isEmpty {
                        Text("No past reservations")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        ForEach(pastReservations) { reservation in
                            ReservationRow(reservation: reservation)
                        }
                    }
                }
            }
            .navigationTitle("Reservation History")
            .refreshable {
                reservationViewModel.loadReservations()
            }
        }
    }
}

struct ReservationRow: View {
    let reservation: Reservation
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @State private var spot: ParkingSpot?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    if let spot = spot {
                        Text("Spot: \(spot.number)")
                            .font(.headline)
                    } else {
                        Text("Spot: Loading...")
                            .font(.headline)
                    }
                    
                    Text(formatDate(reservation.startTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let endTime = reservation.endTime {
                        Text("End: \(formatDate(endTime))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    StatusBadge(status: reservation.status)
                    
                    Text("$\(String(format: "%.2f", reservation.totalCost))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            if reservation.status == .active {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        reservationViewModel.cancelReservation(reservation)
                    }
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadSpot()
        }
    }
    
    private func loadSpot() {
        spot = ParkingService.shared.getSpotById(reservation.parkingSpotId)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: Reservation.ReservationStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .active:
            return .green
        case .completed:
            return .blue
        case .cancelled:
            return .red
        }
    }
}

