//
//  Reservation.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

struct Reservation: Codable, Identifiable {
    let id: String
    let userId: String
    let parkingSpotId: String
    var startTime: Date
    var endTime: Date?
    var status: ReservationStatus
    var totalCost: Double
    var paymentStatus: PaymentStatus
    
    enum ReservationStatus: String, Codable {
        case active = "active"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    enum PaymentStatus: String, Codable {
        case pending = "pending"
        case paid = "paid"
        case refunded = "refunded"
    }
    
    init(id: String = UUID().uuidString, userId: String, parkingSpotId: String, startTime: Date, endTime: Date? = nil, status: ReservationStatus = .active, totalCost: Double = 0.0, paymentStatus: PaymentStatus = .pending) {
        self.id = id
        self.userId = userId
        self.parkingSpotId = parkingSpotId
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.totalCost = totalCost
        self.paymentStatus = paymentStatus
    }
}

