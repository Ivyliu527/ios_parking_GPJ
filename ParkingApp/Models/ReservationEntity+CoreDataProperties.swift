//
//  ReservationEntity+CoreDataProperties.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

extension ReservationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReservationEntity> {
        return NSFetchRequest<ReservationEntity>(entityName: "ReservationEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var parkingSpotId: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var totalCost: Double
    @NSManaged public var paymentStatus: String?
    @NSManaged public var syncedAt: Date?

}

extension ReservationEntity : Identifiable {

}

