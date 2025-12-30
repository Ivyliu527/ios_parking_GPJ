//
//  FavoriteEntity+CoreDataProperties.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

extension FavoriteEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        return NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
    }

    @NSManaged public var userId: String?
    @NSManaged public var parkingLotId: String?
    @NSManaged public var createdAt: Date?

}

extension FavoriteEntity : Identifiable {

}

