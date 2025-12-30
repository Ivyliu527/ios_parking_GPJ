//
//  ParkingLotEntity+CoreDataProperties.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

extension ParkingLotEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ParkingLotEntity> {
        return NSFetchRequest<ParkingLotEntity>(entityName: "ParkingLotEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var totalSpaces: Int32
    @NSManaged public var availableSpaces: Int32
    @NSManaged public var openingHours: String?
    @NSManaged public var priceRules: String?
    @NSManaged public var contactPhone: String?
    @NSManaged public var covered: Bool
    @NSManaged public var cctv: Bool
    @NSManaged public var evChargerCount: Int32
    @NSManaged public var evChargerTypes: [String]?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var cachedAt: Date?

}

extension ParkingLotEntity : Identifiable {

}

