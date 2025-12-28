//
//  ReservationViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

class ReservationViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var activeReservation: Reservation?
    @Published var isLoading = false
    
    private let parkingService = ParkingService.shared
    private let userDefaults = UserDefaults.standard
    private let reservationsKey = "reservations"
    
    init() {
        loadReservations()
    }
    
    func loadReservations() {
        if let data = userDefaults.data(forKey: reservationsKey),
           let decoded = try? JSONDecoder().decode([Reservation].self, from: data) {
            reservations = decoded
            activeReservation = reservations.first { $0.status == .active }
        }
    }
    
    func saveReservations() {
        if let encoded = try? JSONEncoder().encode(reservations) {
            userDefaults.set(encoded, forKey: reservationsKey)
        }
    }
    
    func createReservation(spotId: String, userId: String, duration: TimeInterval) -> Reservation? {
        guard parkingService.reserveSpot(spotId) else {
            return nil
        }
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(duration)
        let spot = parkingService.getSpotById(spotId)
        let pricePerHour = spot?.pricePerHour ?? 0.0
        let totalCost = pricePerHour * (duration / 3600.0)
        
        let reservation = Reservation(
            userId: userId,
            parkingSpotId: spotId,
            startTime: startTime,
            endTime: endTime,
            status: .active,
            totalCost: totalCost,
            paymentStatus: .pending
        )
        
        reservations.append(reservation)
        activeReservation = reservation
        saveReservations()
        
        return reservation
    }
    
    func cancelReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index].status = .cancelled
            parkingService.releaseSpot(reservation.parkingSpotId)
            if activeReservation?.id == reservation.id {
                activeReservation = nil
            }
            saveReservations()
        }
    }
    
    func completeReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index].status = .completed
            reservations[index].endTime = Date()
            parkingService.releaseSpot(reservation.parkingSpotId)
            if activeReservation?.id == reservation.id {
                activeReservation = nil
            }
            saveReservations()
        }
    }
    
    func getReservationsForUser(_ userId: String) -> [Reservation] {
        return reservations.filter { $0.userId == userId }
    }
    
    func calculateRemainingTime(_ reservation: Reservation) -> TimeInterval? {
        guard let endTime = reservation.endTime else { return nil }
        let remaining = endTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
}

