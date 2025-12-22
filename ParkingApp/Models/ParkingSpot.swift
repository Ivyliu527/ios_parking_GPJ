//
//  ParkingSpot.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation

struct ParkingSpot: Codable, Identifiable {
    let id: String
    var number: String
    var floor: Int
    var isAvailable: Bool
    var location: Location
    var pricePerHour: Double
    var features: [String] // e.g., ["EV Charging", "Covered", "Handicap"]
    
    struct Location: Codable {
        var latitude: Double
        var longitude: Double
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    init(id: String = UUID().uuidString, number: String, floor: Int, isAvailable: Bool = true, location: Location, pricePerHour: Double, features: [String] = []) {
        self.id = id
        self.number = number
        self.floor = floor
        self.isAvailable = isAvailable
        self.location = location
        self.pricePerHour = pricePerHour
        self.features = features
    }
}

