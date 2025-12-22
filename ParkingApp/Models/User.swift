//
//  User.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var phoneNumber: String
    var licensePlate: String?
    
    init(id: String = UUID().uuidString, email: String, name: String, phoneNumber: String, licensePlate: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.licensePlate = licensePlate
    }
}

