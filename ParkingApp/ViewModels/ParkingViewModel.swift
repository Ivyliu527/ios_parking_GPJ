//
//  ParkingViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class ParkingViewModel: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var filteredSpots: [ParkingSpot] = []
    @Published var selectedSpot: ParkingSpot?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFloor: Int? = nil
    @Published var showOnlyAvailable = true
    
    private let parkingService = ParkingService.shared
    
    init() {
        loadParkingSpots()
    }
    
    func loadParkingSpots() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.parkingSpots = self.parkingService.parkingSpots
            self.applyFilters()
            self.isLoading = false
        }
    }
    
    func applyFilters() {
        filteredSpots = parkingSpots
        
        // Filter by availability
        if showOnlyAvailable {
            filteredSpots = filteredSpots.filter { $0.isAvailable }
        }
        
        // Filter by floor
        if let floor = selectedFloor {
            filteredSpots = filteredSpots.filter { $0.floor == floor }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filteredSpots = filteredSpots.filter {
                $0.number.localizedCaseInsensitiveContains(searchText) ||
                $0.features.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func selectSpot(_ spot: ParkingSpot) {
        selectedSpot = spot
    }
    
    func getFloors() -> [Int] {
        return Array(Set(parkingSpots.map { $0.floor })).sorted()
    }
}

