//
//  ParkingService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation
import Combine

class ParkingService: ObservableObject {
    static let shared = ParkingService()
    
    @Published var parkingSpots: [ParkingSpot] = []
    
    private init() {
        loadMockData()
    }
    
    func loadMockData() {
        // Mock parking spots data
        parkingSpots = [
            ParkingSpot(
                number: "A-101",
                floor: 1,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3193, longitude: 114.1694),
                pricePerHour: 15.0,
                features: ["Covered", "Near Elevator"]
            ),
            ParkingSpot(
                number: "A-102",
                floor: 1,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3194, longitude: 114.1695),
                pricePerHour: 15.0,
                features: ["Covered"]
            ),
            ParkingSpot(
                number: "A-103",
                floor: 1,
                isAvailable: false,
                location: ParkingSpot.Location(latitude: 22.3195, longitude: 114.1696),
                pricePerHour: 15.0,
                features: ["Covered", "EV Charging"]
            ),
            ParkingSpot(
                number: "B-201",
                floor: 2,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3196, longitude: 114.1697),
                pricePerHour: 12.0,
                features: []
            ),
            ParkingSpot(
                number: "B-202",
                floor: 2,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3197, longitude: 114.1698),
                pricePerHour: 12.0,
                features: ["Handicap"]
            ),
            ParkingSpot(
                number: "C-301",
                floor: 3,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3198, longitude: 114.1699),
                pricePerHour: 10.0,
                features: []
            ),
            ParkingSpot(
                number: "C-302",
                floor: 3,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3199, longitude: 114.1700),
                pricePerHour: 10.0,
                features: ["EV Charging"]
            )
        ]
    }
    
    func getAvailableSpots() -> [ParkingSpot] {
        return parkingSpots.filter { $0.isAvailable }
    }
    
    func getSpotById(_ id: String) -> ParkingSpot? {
        return parkingSpots.first { $0.id == id }
    }
    
    func reserveSpot(_ spotId: String) -> Bool {
        if let index = parkingSpots.firstIndex(where: { $0.id == spotId && $0.isAvailable }) {
            parkingSpots[index].isAvailable = false
            return true
        }
        return false
    }
    
    func releaseSpot(_ spotId: String) {
        if let index = parkingSpots.firstIndex(where: { $0.id == spotId }) {
            parkingSpots[index].isAvailable = true
        }
    }
}
